get '/files/rs/:systematic_review_id/assign_to_canonical_documents' do |rs_id|
  halt_unless_auth('file_admin')
  rs=SystematicReview[rs_id]

  raise Buhos::NoReviewIdError, rs_id if !rs


  require 'pdf-reader'
  # Solo buscar en los files que no tienen canonico asignado
  pdf_por_revisar=file_Rs.files_sin_cd(rs_id).where(:filetype=>'application/pdf')
  pdf_por_revisar.each do |pdf|
    begin
      reader=PDF::Reader.new(pdf.absolute_path(dir_files))
        doi=nil
        info=reader.info
        if(info[:doi])
          doi=info[:doi]
        elsif(info[:Subject])
          doi=find_doi(info[:Subject])
        end
        if doi.nil?
          primera_pagina=reader.pages[0].text
          doi=find_doi(primera_pagina)
        end

        if(doi)
          cd=CanonicalDocument.where(:doi=>doi)
          if cd.count>0
            $db.transaction do
              FileCd.insert(:file_id=>pdf[:id], :canonical_document_id=>cd.first[:id])
            end
            add_message("Agregado file #{pdf[:filename]} a canónico #{cd[:title]}")
          else
            add_message("No puedo encontrar doi: #{doi} en los canonicos", :warning)
          end
        else
          add_message("No puedo encontrar doi en el documento #{pdf[:filename]}", :warning)
        end

      rescue Exception=>e
        $log.error("Error on file: #{pdf[:filename]}")
        add_message("Error on file: #{pdf[:filename]}", :error)
        #raise
      end
    end
  redirect back
end



get '/ViewerJS/' do
  halt_unless_auth('file_view')
  send_file("#{dir_base}/public/ViewerJS/index.html")
end

get '/ViewerJS/..file/:id/download' do |id|
  halt_unless_auth('file_view')

  file=IFile[id]
  return 404 if file.nil?

  #headers["Content-Disposition"] = "attachment;filename=#{file[:filename]}"

  content_type file[:filetype]
  send_file(file.absolute_path(dir_files))

end

get '/file/:id/download' do |id|
  halt_unless_auth('file_view')

  file=IFile[id]
  return 404 if file.nil?

  #headers["Content-Disposition"] = "attachment;filename=#{file[:filename]}"

  content_type file[:filetype]
  send_file(file.absolute_path(dir_files))
end




get '/file/:id/page/:pagina/:format' do |id,pagina,format|
  halt_unless_auth('file_view')

  file=IFile[id]
  pagina=pagina.to_i
  return 404 if file.nil?
  filepath=file.absolute_path(dir_files)

  if file[:filetype]=="application/pdf"

    if format=='text'
      require 'pdf-reader'
      reader=PDF::Reader.new(filepath)
      file.update(:pages=>reader.pages.length) if file[:pages].nil?
      return "No existe pagina" if reader.pages.length<pagina
      reader.pages[pagina-1].text
    elsif format=='image'
      require 'grim'
      pdf   = Grim.reap(filepath)
      return "No existe pagina" if pdf.count<pagina or pagina<1
      file.update(:pages=>pdf.count) if file[:pages].nil?
      filepath_image="#{dir_files}/pdf_imagenes/#{file[:sha256][0]}/#{file[:sha256]}_#{pagina}.png"
      #$log.info(File.dirname(filepath_image))
      FileUtils.mkdir_p File.dirname(filepath_image) unless File.exist? File.dirname(filepath_image)
      unless File.exist? filepath_image
        pdf[pagina-1].save(filepath_image,{
            :density=>300,
            :alpha=>"Set"
        })
      end
      headers["Content-Disposition"] = "inline;filename=#{File.basename(filepath_image)}"
      content_type "image/png"
      send_file(filepath_image)
    else
      raise "No existe el format"
    end
  else
    return 500
  end
#  headers["Content-Disposition"] = "inline;filename=#{file[:filename]}"

#  content_type file[:filetype]
#  send_file(file.absolute_path(dir_files))
end


get '/file/:id/view' do |id|
  halt_unless_auth('file_view')

  file=IFile[id]
  return 404 if file.nil?

  headers["Content-Disposition"] = "inline;filename=#{file[:filename]}"

  content_type file[:filetype]
  send_file(file.absolute_path(dir_files))
end




post '/file/assign_to_canonical' do
  halt_unless_auth('canonical_document_admin')

  file=IFile[params['file_id']]
  return 404 if file.nil?
  acd=FileCd.where(:file_id=>file.id)


  if params['cd_id']==""
    acd.delete
    return I18n::t("file_handler.no_canonical_document")
  else
    cd=CanonicalDocument[params['cd_id']]
    return 404 if !cd
    if acd.empty?
      FileCd.insert(:file_id=>file.id,:canonical_document_id=>cd.id,:not_consider=>false)
    else
      FileCd.where(:file_id=>file.id).update(:canonical_document_id=>cd.id)
    end
    return "<a href='/canonical_document/#{cd[:id]}'>#{cd[:title][0..50]}</a>"
  end

end

post '/file/hide_cd' do
  halt_unless_auth('canonical_document_admin')
  file=IFile[params['file_id']]
  cd=CanonicalDocument[params['cd_id']]
  return 404 if file.nil? or cd.nil?

  FileCd.where(:file_id=>file.id, :canonical_document_id=>cd.id).update(:not_consider=>true)
  return 200
end


post '/file/show_cd' do
  halt_unless_auth('canonical_document_admin')
  file=IFile[params['file_id']]
  cd=CanonicalDocument[params['cd_id']]

  raise Buhos::NoFileIdError , params['file_id'] unless file
  raise NoCdIdError   , params['cd_id'] unless cd

  FileCd.where(:file_id=>file.id, :canonical_document_id=>cd.id).update(:not_consider=>false)
  return 200
end
post '/file/unassign_cd' do
  halt_unless_auth('canonical_document_admin')
  file=IFile[params['file_id']]
  cd=CanonicalDocument[params['cd_id']]

  raise Buhos::NoFileIdError , params['file_id'] unless file
  raise NoCdIdError   , params['cd_id'] unless cd

  FileCd.where(:file_id=>file.id, :canonical_document_id=>cd.id).delete
  return 200
end


post '/file/unassign_sr' do
  halt_unless_auth('review_admin')
  rs=SystematicReview[params['rs_id']]
  return 404 if file.nil? or rs.nil?
  file_Rs.where(:file_id=>file.id, :systematic_review_id=>rs.id).delete
  return 200
end

post '/file/delete' do
  halt_unless_auth('file_admin')

  file=IFile[params['file_id']]

  return 404 if file.nil?
  FileSr.where(:file_id => file.id).delete
  FileCd.where(:file_id => file.id).delete
  file.delete
  return 200
end

# Method put

put '/file/edit_field/:campo' do |field|
  halt_unless_auth('file_admin')

  return 505 unless %w{filename filetype}.include? field
  pk = params['pk']
  value = params['value']
  @arc=IFile[pk]
  @arc.update(field.to_sym => value.chomp)
  return true
end