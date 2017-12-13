# encoding: UTF-8



require "bundler/setup"
require 'sinatra'
# Vamos a activar el reloader en todos los casos
# Como el sistema está en vivo, es más peligroso hacer lo otro
require 'haml'
require 'logger'


require 'dotenv'

Dotenv.load("./.env")


require 'i18n'
#require 'i18n/backend/fallbacks'





set :session_secret, 'super secret2'

# Arreglo a lo bestia para el force_encoding

unless "".respond_to? :force_encoding
  class String
    def force_encoding(s)
      self
    end
  end
end




Dir.glob("lib/*.rb").each do |f|
  require_relative(f)
end

Dir.glob("controllers/**/*.rb").each do |f|
  require_relative(f)
end


if !File.exists?("log")
  FileUtils.mkdir("log")
end
$log = Logger.new('log/app.log')
$log_sql = Logger.new('log/app_sql.log')



require_relative 'model/init.rb'
require_relative 'model/models.rb'
require_relative 'lib/partials.rb'


Dir.glob("model/*.rb").each do |f|
  require_relative(f)
end


require 'digest/sha1'


enable :logging, :dump_errors, :raise_errors, :sessions




configure :development do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions


end

configure :production do |c|
  c.enable :logging, :dump_errors, :raise_errors, :sessions, :show_errors, :show_exceptions

end



helpers Sinatra::Partials
helpers Sinatra::Mobile

# Internacionalización!
#require 'i18n'


#::I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)





# this is required if you want to assume the default path
set :root, File.dirname(__FILE__)

# an alternative would be to set the locales path
#set :locales, File.join(File.dirname(__FILE__), 'locales/es.yml')

# then just register the extension
#register Sinatra::I18n





helpers do

  include DOIHelpers

  def get_lang(http_lang)
    accepted=["en","es"]
    unless http_lang.nil?
      langs=http_lang.split(",").map {|v|
        v.split(";")[0].split("-")[0]
      }.each  {|l|
        return l if accepted.include? l
      }
    end
    "en"
  end
  # Entrega el acceso al log
  def log
    $log
  end
  def dir_archivos
    dir=File.expand_path(File.dirname(__FILE__)+"/usr/archivos")
    FileUtils.mkdir_p(dir) unless File.exist? dir
    dir
  end
  
  def lf_to_br(t)
    t.nil? ? "" : t.split("\n").join("<br/>")
  end
  
  
  # Entrega el valor para un id de configuración
  def config_get(id)
    Configuracion.get(id)
  end
  # Define el valor para un id de configuración
  def config_set(id,valor)
    Configuracion.set(id,valor)
  end
  def tiempo_sql(tiempo)
    tiempo.strftime("%Y-%m-%d %H:%M:%S")
  end

  def url(ruta)
    if @mobile
      "/mob#{ruta}"
    else
      ruta
    end
  end

  def put_editable(b,&block)
    params=b.params
    value=params['value'].chomp
    return 505 if value==""
    id=params['pk']
    block.call(id, value)
    return 200
  end

  def class_bootstrap_contextual(cond, prefix, clase, clase_no="default")
    cond ? "#{prefix}-#{clase}" : "#{prefix}-#{clase_no}"
  end

  def decision_class_bootstrap(tipo, prefix)
    suffix=case tipo
             when nil
               "default"
             when "yes"
               "success"
             when "no"
               "danger"
             when "undecided"
               "warning"
           end
    "#{prefix}-#{suffix}"
  end

  def a_textarea_editable(id, prefix, data_url, v, default_value="--")
    url_s=url(data_url)

    "<a class='textarea_editable' data-pk='#{id}' data-url='#{url_s}' href='#' id='#{prefix}-#{id}' data-placeholder='#{default_value}'>#{v}</a>"
  end


  def a_editable(id, prefix, data_url, v,default_value="--")
    url_s=url(data_url)
    #val=(v.nil? ? default_value : v)
    val=v
    "<a class='nombre_editable' data-pk='#{id}' data-url='#{url_s}' href='#' id='#{prefix}-#{id}' data-placeholder='#{default_value}'>#{val}</a>"
  end


end




error 403 do
  haml :error403
end
error 404 do
  haml :error404
end


before do
  if session['lang'].nil?
    session['lang']=get_lang(request.env['HTTP_ACCEPT_LANGUAGE'])
    session['lang']=='en' unless ['en','es'].include? session['lang']
  end
  I18n.locale = session['lang'].to_sym

end


# INICIO

get '/' do
  log.info("Parto en /")
  if session['user'].nil?
    log.info("/ sin id: basico")
    redirect url('/login')
  else
    #begin
      redirect url('/'+session['rol_id'])
      raise "Error"
    #rescue
    #  session['id']=nil
    #  redirect('/error')
    #end
  end
end






