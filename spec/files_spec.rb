require 'spec_helper'

shared_examples "pdf file" do
  let(:filesize) {File.size(filepath)}
  it "should response be ok" do expect(last_response).to be_ok end
  it "should content type be application/pdf" do expect(last_response.header['Content-Type']).to eq('application/pdf') end
  it "should content length be correct" do expect(last_response.header['Content-Length']).to eq(filesize.to_s) end

end

describe 'Files' do
  before(:all) do
    RSpec.configure { |c| c.include RSpecMixin }
    @temp=configure_empty_sqlite
    Revision_Sistematica.insert(:nombre=>'Test Review', :grupo_id=>1, :administrador_revision=>1)
    login_admin
  end
  def filepath
    filename="2010_Kiritchenko et al._ExaCT automatic extraction of clinical trial characteristics from journal publications.pdf"
    File.expand_path("#{File.dirname(__FILE__)}/../docs/guide_resources/#{filename}")
  end


  context 'when upload a file using /review/files/add' do
    before(:context) do
      uploaded_file=Rack::Test::UploadedFile.new(filepath, "application/pdf")
      post '/review/files/add', revision_sistematica_id:sr_by_name_id('Test Review'), archivos:[uploaded_file]
    end
    let(:file) {Archivo[1]}
    let(:app_helpers) {Class.new {extend Buhos::Helpers}}
    it "should response will be redirect" do expect(last_response).to be_redirect end
    it "should create an file object" do expect(file).to be_truthy end
    it "should create an file object with correct mime type" do expect(file[:archivo_tipo]).to eq("application/pdf") end
    it "should create a file on correct directory" do
      path="#{app_helpers.dir_archivos}/#{file[:archivo_ruta]}"
      expect(File.exist? path).to be true
    end
  end

  context "when access ViewerJs" do
    it "should return correct html" do
      get '/ViewerJS/index.html'
      expect(last_response).to be_ok
      expect(last_response.body).to include("This file is the compiled version of the ViewerJS module")
    end
  end
  context "when access /ViewerJS/..file/:id/download format, response " do
    before(:context) do
      get '/ViewerJS/..file/1/download'
    end

    include_examples "pdf file"

  end
  context "when user downloads a file, response" do
    before(:context) do
      get '/file/1/download'
    end
    include_examples "pdf file"
  end

  context "when user downloads a file, response" do
    before(:context) do
      get '/file/1/view'
    end
    include_examples "pdf file"
    it {expect(last_response.header['Content-Disposition']).to include('inline') }
  end


  context "when user retrieves a page from a pdf as text, response" do
    before(:context) do
      get '/file/1/page/1/text'
    end
    it {expect(last_response).to be_ok }
    it {expect(last_response.header['Content-Type']).to include("text/html") }
    it {expect(last_response.body).to include("ExaCT")}
  end
  # Works, but is very slow
  context "when user retrieves a page from a pdf as image, response" do
    before(:context) do
      get '/file/1/page/17/image'
    end
    it {expect(last_response).to be_ok }
    it {expect(last_response.header['Content-Type']).to include("image/png") }
    it {expect(last_response.header['Content-Length'].to_i).to be >0}
  end

  context "when change attribute of a file" do
    before(:context) do
      put '/file/edit_field/archivo_nombre', {pk:1, value:'exact.pdf'}
    end
    it {expect(last_response).to be_ok }
    it "should row on database be changed" do
      expect(Archivo[1][:archivo_nombre]).to eq('exact.pdf')
    end

  end

  context "when file is deleted" do
    before(:context) do
      post '/file/delete', {archivo_id:1}
    end
    it {expect(last_response).to be_ok }
    it "archivo object doesn't exists" do
      expect(Archivo[1]).to be_nil
    end


  end

end