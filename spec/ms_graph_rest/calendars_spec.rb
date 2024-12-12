require 'spec_helper'

module MsGraphRest
  RSpec.describe Calendars do
    let(:client) { MsGraphRest.new_client(access_token: "123") }
    let(:calendars) { client.calendars }

    describe 'Get all calendars' do
      before do
        stub_request(:get, "https://graph.microsoft.com/v1.0/me/calendars")
          .to_return(status: 200, body: body, headers: {})
      end

      let(:body) do
        '{
          "value": [
            {
              "id": "AAMkAGI2TGuLAAA=",
              "name": "Calendar",
              "color": "auto",
              "changeKey": "nfZyf7VcrEKLNoU37KWlkQAAA0x0+w==",
              "canShare":true,
              "canViewPrivateItems":true,
              "hexColor": "",
              "canEdit":true,
              "allowedOnlineMeetingProviders": [
                  "teamsForBusiness"
              ],
              "defaultOnlineMeetingProvider": "teamsForBusiness",
              "isTallyingResponses": true,
              "isRemovable": false,
              "owner":{
                  "name":"Samantha Booth",
                  "address":"samanthab@adatum.onmicrosoft.com"
              }
            }
          ]
        }'
      end

      it do
        result = calendars.get
        expect(result.size).to eq(1)
        expect(result.first)
          .to have_attributes(id: "AAMkAGI2TGuLAAA=",
                              name: "Calendar",)
        expect(result.next_get_query).to be_nil
      end
    end

    describe 'Get calendars with select and filters' do
      before do
        select = "name,id"
        filter = "name%20eq%20'Calendar')"
        stub_request(:get, "https://graph.microsoft.com/v1.0/me/calendars?$filter=#{filter}&$select=#{select}")
          .to_return(status: 200, body: body, headers: {})
      end

      let(:body) do
        '{
          "value": [
            {
                "id": "AAMkAGI2TGuLAAA=",
                "name": "Calendar"
            }
          ]
        }'
      end

      it do
        results = calendars
                  .filter("name eq 'Calendar')")
                  .select("name,id")
                  .get
        expect(results.size).to eq(1)
        expect(results.first)
          .to have_attributes(name: 'Calendar')
      end
    end
  end
end
