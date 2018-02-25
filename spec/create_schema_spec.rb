require_relative 'spec_helper'



describe 'Buhos::SchemaCreation' do
  let(:db) {Buhos::SchemaCreation.create_db_from_scratch("sqlite::memory:")}
  context '#create_db_from_scratch' do
    it "create two users" do
      expect(db["SELECT * FROM usuarios"].all.count).to eq(2)
    end
    it "create 6 taxonomies" do
      expect(db["SELECT * FROM sr_taxonomies"].all.count).to eq(6)
    end
    it "create 20 categories" do
      expect(db["SELECT * FROM sr_taxonomy_categories"].all.count).to eq(20)
    end

  end
end