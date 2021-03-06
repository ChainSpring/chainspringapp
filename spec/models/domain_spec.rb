require 'rails_helper'

RSpec.describe Domain, type: :model do
  describe "creation" do
    before do
      @topic = FactoryBot.create(:topic)
    end

    it "can be created" do
      expect(@topic).to be_valid
    end

    it "cannot be duplicated" do
      @topic2 = FactoryBot.build(:topic)
      expect(@topic2).to_not be_valid
    end

    it "can be created without a reference" do
      topic2 = FactoryBot.create(:topic_without_ref)
      expect(topic2).to be_valid
    end

  end
end
