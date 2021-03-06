require 'spec_helper' 

describe "bulk_upload" do 
 
  it "should upload a bulk for a collection", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path

  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click

    sleep 5

  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
	  
    sleep 5

    click_link "Upload it for bulk sites updates"
  	sleep 3
  	page.has_content? ('#upload')
  	page.attach_file 'upload', 'Test Collection_sites.csv'
  	
    click_link "resmap-id"

    page.find(:xpath, '//div[@id="columnUsageTemplate"]/div[1]/div/div[@class="popup-row"]/div[@class="left"][2]/select').click

    select 'Ignore'
    click_button "Apply"

    click_button "Start importing"
    sleep 3
    page.should have_content "Importing"

    # click_link ('Collections')
    # sleep 30
    # page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    # sleep 25


    # page.should have_content "Abbey"
    # page.should have_content "Kratos"

    sleep 2

  	page.save_screenshot ("Upload a bulk.png")
  end
end