require 'spec_helper'
describe Spotlight::BlacklightConfigurationsController, :type => :controller do
  routes { Spotlight::Engine.routes }
  let(:exhibit) { FactoryGirl.create(:exhibit) }

  describe "when the user is not authorized" do
    before do
      sign_in FactoryGirl.create(:exhibit_visitor)
    end

    it "should deny access" do
      get :metadata_fields, exhibit_id: exhibit 
      expect(response).to redirect_to main_app.root_path
      expect(flash[:alert]).to be_present
    end
    
    it "should deny access" do
      get :edit_metadata_fields, exhibit_id: exhibit 
      expect(response).to redirect_to main_app.root_path
      expect(flash[:alert]).to be_present
    end
    
    it "should deny access" do
      get :edit_facet_fields, exhibit_id: exhibit 
      expect(response).to redirect_to main_app.root_path
      expect(flash[:alert]).to be_present
    end
  end

  describe "when not logged in" do
    describe "#update" do
      it "should not be allowed" do
        patch :update, exhibit_id: exhibit 
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end

    describe "#edit_metadata_fields" do
      it "should not be allowed" do
        get :edit_metadata_fields, exhibit_id: exhibit
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end

    describe "#edit_facet_fields" do
      it "should not be allowed" do
        get :edit_facet_fields, exhibit_id: exhibit
        expect(response).to redirect_to main_app.new_user_session_path
      end
    end
  end

  describe "when signed in" do
    let(:user) { FactoryGirl.create(:exhibit_admin, exhibit: exhibit) }
    before {sign_in user }

    describe "#edit_metadata_fields" do
      it "should be successful" do
        expect(controller).to receive(:add_breadcrumb).with("Home", exhibit)
        expect(controller).to receive(:add_breadcrumb).with("Curation", exhibit_dashboard_path(exhibit))
        expect(controller).to receive(:add_breadcrumb).with("Metadata", exhibit_edit_metadata_path(exhibit))
        get :edit_metadata_fields, exhibit_id: exhibit
        expect(response).to be_successful
      end
    end

    describe "#edit_facet_fields" do
      it "should be successful" do
        expect(controller).to receive(:add_breadcrumb).with("Home", exhibit)
        expect(controller).to receive(:add_breadcrumb).with("Curation", exhibit_dashboard_path(exhibit))
        expect(controller).to receive(:add_breadcrumb).with("Search facets", exhibit_edit_facets_path(exhibit))
        allow(controller).to receive_message_chain(:repository, :send_and_receive).and_return({})
        get :edit_facet_fields, exhibit_id: exhibit
        expect(response).to be_successful
      end
    end

    describe "#edit_sort_fields" do
      it "should be successful" do
        expect(controller).to receive(:add_breadcrumb).with("Home", exhibit)
        expect(controller).to receive(:add_breadcrumb).with("Curation", exhibit_dashboard_path(exhibit))
        expect(controller).to receive(:add_breadcrumb).with("Sort fields", exhibit_edit_sort_fields_path(exhibit))
        get :edit_sort_fields, exhibit_id: exhibit
        expect(response).to be_successful
      end
    end

    describe "#metadata_fields" do
      it "should be successful" do
        get :metadata_fields, exhibit_id: exhibit, format: 'json'
        expect(response).to be_successful
        expect(JSON.parse(response.body).keys).to eq exhibit.blacklight_config.index_fields.keys
      end
    end

    describe "#available_search_views" do
      it "should be successful" do
        get :available_search_views, exhibit_id: exhibit, format: 'json'
        expect(response).to be_successful
        available = JSON.parse(response.body)
        expect(available).to match_array ['list', 'gallery', 'slideshow']
      end
    end

    describe "#alternate_count" do
      before { controller.instance_variable_set(:@blacklight_configuration, exhibit.blacklight_configuration) }
      subject { controller.alternate_count }
      its(:count) { should eq 7 }
      it "should have correct numbers" do
        expect(subject['genre_ssim']).to eq 54
      end
    end

    describe "#update" do

      it "should update metadata fields" do
        blacklight_config = Blacklight::Configuration.new
        blacklight_config.add_index_field ['a', 'b', 'c', 'd', 'e', 'f']
        allow(::CatalogController).to receive_messages(blacklight_config: blacklight_config)
        patch :update, exhibit_id: exhibit, blacklight_configuration: {
          index_fields: {
            c: { enabled: true, show: true},
            d: { enabled: true, show: true},
            e: { enabled: true, list: true},
            f: { enabled: true, list: true}
          }
        }

        expect(flash[:notice]).to eq "The exhibit was successfully updated."
        expect(response).to redirect_to exhibit_edit_metadata_path(exhibit)
        assigns[:exhibit].tap do |saved|
          expect(saved.blacklight_configuration.index_fields).to include 'c', 'd', 'e', 'f'
        end
      end

      it "should update facet fields" do
        patch :update, exhibit_id: exhibit, blacklight_configuration: { 
          facet_fields: { 'genre_ssim' => { enabled: '1', label: "Label"} }  
        }
        expect(flash[:notice]).to eq "The exhibit was successfully updated."
        expect(response).to redirect_to exhibit_edit_facets_path(exhibit)
        assigns[:exhibit].tap do |saved|
          expect(saved.blacklight_configuration.facet_fields.keys).to eq ['genre_ssim']
        end
      end

      it "should update sort fields" do
        patch :update, exhibit_id: exhibit, blacklight_configuration: { 
          sort_fields: {"relevance"=>{"enabled" => "1", "label" => "Relevance"}, "title"=>{"enabled" => "1", "label" => "Title"}, "type"=>{"enabled" => "1", "label" => "Type"}, "date"=>{"enabled" => "0", "label" => "Date"}, "source"=>{"enabled" => "0", "label" => "Source"}, "identifier"=>{"enabled" => "0", "label" => "Identifier"}}
        }
        expect(flash[:notice]).to eq "The exhibit was successfully updated."
        expect(response).to redirect_to exhibit_edit_sort_fields_path(exhibit)
        assigns[:exhibit].tap do |saved|
          expect(saved.blacklight_configuration.sort_fields).to eq(
            {"relevance" => {"label"=>"Relevance", "enabled"=>true},
             "title" => {"label" => "Title", "enabled"=>true},
             "type" => {"label" => "Type", "enabled"=>true},
             "date" => {"label" => "Date", "enabled"=>false},
             "source" => {"label" => "Source", "enabled"=>false},
             "identifier" => {"label" => "Identifier", "enabled"=>false}
            }
          )
        end
      end
    end
  end
end
