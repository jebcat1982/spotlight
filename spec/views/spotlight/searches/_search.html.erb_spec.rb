require 'spec_helper'

describe "spotlight/searches/_search.html.erb", :type => :view do
  
  let(:search) { stub_model(Spotlight::Search, exhibit: FactoryGirl.create(:exhibit),
        id: 99, title: "Title1", query_params: { f: { genre_ssim: ["xyz"]}}) }
  before do
    allow(view).to receive(:edit_search_path).and_return("/edit")
    allow(view).to receive(:search_path).and_return("/search")
    allow(search).to receive_message_chain(:thumbnail, :image, thumb: "/some/image")
    allow(search).to receive(:params).and_return({})

    form_for(search, url: '/update') do |f|
      @f = f
    end
  end

  it "renders a list of pages" do
    render :partial => "spotlight/searches/search", :locals => { f: @f}
    expect(rendered).to have_selector "li[data-id='99']"
    expect(rendered).to have_selector '.panel-heading .main .title', text: 'Title1'
    expect(rendered).to have_selector 'img[src="/some/image"]'
    expect(rendered).to have_selector 'input[type=hidden][data-property=weight]'
  end
end

