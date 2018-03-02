module Buhos
  # Delegation pattern for Sequel::Database
  # Used on spec to change the database between tests
  class DBAdapter
    attr_accessor :logger
    def initialize
      @current=nil
    end
    def current
      @current
    end
    def use_db(db)
      @current=db
      db.loggers << @logger
    end
    # This is ugly. I know.
    # I just do it to allow testing
    def update_model_association
      ::IFile.dataset=self[:files]
      ::FileCd.dataset=self[:file_cds]
      ::FileSr.dataset=self[:file_srs]
      ::AllocationCd.dataset=self[:allocation_cds]
      ::BibliographicDatabase.dataset=self[:bibliographic_databases]
      ::Search.dataset=self[:searches]


      ::CanonicalDocument.dataset=self[:canonical_documents]
      ::CrossrefDoi.dataset=self[:crossref_dois]
      ::CrossrefQuery.dataset=self[:crossref_queries]
      ::Decision.dataset=self[:decisions]
      ::Group.dataset=self[:groups]
      ::Message.dataset=self[:messages]
      ::MessageSr.dataset=self[:message_srs]
      ::MessageSrSeen.dataset=self[:message_sr_seens]
      ::Reference.dataset=self[:bib_references]
      ::RecordsReferences.dataset=self[:records_references]
      ::Resolution.dataset=self[:resolutions]
      ::Record.dataset=self[:records]
      ::Tag.dataset=self[:tags]
      ::T_Class.dataset=self[:t_classes]
      ::TagInClass.dataset=self[:tag_in_classes]
      ::TagInCd.dataset=self[:tag_in_cds]
      ::TagBwCd.dataset=self[:tag_bw_cds]
      ::SystematicReview.dataset=self[:systematic_reviews]
      ::SrField.dataset=self[:sr_fields]
      ::User.dataset=self[:users]
      ::Authorization.dataset=self[:authorizations]
      ::Role.dataset=self[:roles]
      ::Scopus_Abstract.dataset=self[:scopus_abstracts]
      ::Group.dataset=self[:groups]
      ::GroupsUser.dataset=self[:groups_users]
      ::AuthorizationsRole.dataset=self[:authorizations_roles]


      ::Search.many_to_many :records, :class=>Record


      ::Record.many_to_one :canonical_document, :class=>CanonicalDocument

      ::Reference.many_to_many :records
      ::SystematicReview.many_to_one :group
      ::SystematicReview.one_to_many :messages_srs, :class=>MessageSr
      ::Group.many_to_many :users
    end
    def method_missing(m, *args, &block)
      #puts "#{m}: #{args}"
      @current.send(m, *args, &block)
      #puts "There's no method called #{m} here -- please try again."
    end
    def self.method_missing(m, *args, &block)
      raise "Can't handle this"
    end
  end
end