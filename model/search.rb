require_relative "revision_sistematica.rb"
require_relative "registro.rb"

require 'digest'

class Search < Sequel::Model
  many_to_one :systematic_review, :class=>SystematicReview
  many_to_one :bibliographic_database, :class=>BibliographicDatabase
  many_to_many :records, :class=>Record


  SOURCES=[:database_search,
           :informal_search,
           :backward_snowballing,
           :forward_snowballing
  ]

  SOURCES_NAMES={:database_search=> "source.database_search",
                 :informal_search => "source.informal_search",
                 :backward_snowballing=> "source.backward_snowballing",
                 :forward_snowballing=> "source.forward_snowballing"}

  SOURCES_NAMES_SHORT={:database_search=> "source.database_search_short",
                 :informal_search => "source.informal_search_short",
                 :backward_snowballing=> "source.backward_snowballing_short",
                 :forward_snowballing=> "source.forward_snowballing_short"}


  def name
    "#{self[:id]} - #{I18n::t(Search.get_source_name(self[:source]))} - #{self.date_creation} - #{self.bibliographical_database_name}"
  end


  def self.get_source_name(source)
    source.nil? ? "source.error_no_source" : SOURCES_NAMES[source.to_sym]
  end

  def self.get_source_name_short(source)
    source.nil? ? "source.error_no_source" : SOURCES_NAMES_SHORT[source.to_sym]

  end

  def source_name
    Search.get_source_name(self[:source])
  end

  def source_name_short
    Search.get_source_name_short(self[:source])
  end

  def user_name
    user_id.nil? ? I18n::t(:No_username) : User[self.user_id].name
  end
  def records_n
    records.count
  end
  def references_n
    references.count
  end

  def bibliographical_database_name
    bibliographic_database ? bibliographic_database.name : nil
  end
  def references
    ref_ids=$db["SELECT DISTINCT(rr.reference_id) FROM records_references rr INNER JOIN records_searches br ON rr.record_id=br.record_id WHERE br.search_id=?", self[:id]].map {|v| v[:reference_id]}
    Reference.where(:id=>ref_ids)
  end

  def references_with_canonical_n(limit=nil)
    sql_limit= limit.nil? ? "" : "LIMIT #{limit.to_i}"
    $db["SELECT d.id, d.title, d.journal,d.volume, d.pages, d.author, d.year,COUNT(DISTINCT(br.record_id)) as n_records, COUNT(DISTINCT(r.id)) as n_references FROM canonical_documents d INNER JOIN references r ON d.id=r.canonical_document_id  INNER JOIN records_references rr ON r.id=rr.reference_id INNER JOIN records_searches br ON rr.record_id=br.record_id WHERE br.search_id=? GROUP BY d.id ORDER BY n_records DESC #{sql_limit}", self[:id] ]
  end

  def references_sin_canonico_n(limit=nil)
    sql_limit= limit.nil? ? "" : "LIMIT #{limit.to_i}"
    $db["SELECT r.id, r.text, COUNT(DISTINCT(br.record_id)) as n FROM references r INNER JOIN records_references rr ON r.id=rr.reference_id INNER JOIN records_searches br ON rr.record_id=br.record_id WHERE br.search_id=? AND canonical_document_id IS NULL GROUP BY r.id ORDER BY n DESC #{sql_limit}", self[:id] ]
  end

  def references_sin_canonico_con_doi_n(limit=nil)
    sql_limit= limit.nil? ? "" : "LIMIT #{limit.to_i}"
    $db["SELECT r.doi, MIN(r.text) as text , COUNT(DISTINCT(br.record_id)) as n FROM references r INNER JOIN records_references rr ON r.id=rr.reference_id INNER JOIN records_searches br ON rr.record_id=br.record_id WHERE br.search_id=? AND canonical_document_id IS NULL AND doi IS NOT NULL GROUP BY r.doi ORDER BY n DESC #{sql_limit}", self[:id]]
  end



  def update_records(ref_ids)
    records_ya_ingresados=$db["SELECT record_id FROM records_searches WHERE search_id=?", self[:id]].map {|v| v[:record_id]}
    records_por_ingresar = ref_ids - records_ya_ingresados
    records_por_borrar = records_ya_ingresados - ref_ids
    if records_por_ingresar
      $db[:records_searches].multi_insert (records_por_ingresar.map {|v| {:record_id => v, :search_id => self[:id]}})
    end
    if records_por_borrar
      $db[:records_searches].where(:search_id => self[:id], :record_id => records_por_borrar).delete
    end
  end
  #
  # @return

end