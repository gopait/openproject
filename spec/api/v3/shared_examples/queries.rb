require "set"

RSpec.shared_examples 'API 200 OK response' do
  it 'should respond with 200' do
    last_response.status.should eq(200)
  end

  it 'should respond with the correct resource object' do
    last_response.body.should be_json_eql(resource_object.id.to_json).at_path('id')
  end
end

RSpec.shared_examples '401 Unauthorized response' do
  it 'should respond with 401' do
    last_response.status.should eq(401)
  end

  it 'should respond with explanatory error message' do
    errors = %([{ "key": "not_authenticated", "messages": ["You need to be authenticated to access this resource"]}])
    last_response.body.should be_json_eql(errors).at_path("errors")
  end
end

RSpec.shared_examples '403 Forbidden response' do
  it 'should respond with 403' do
    last_response.status.should eq(403)
  end

  it 'should respond with explanatory error message' do
    errors = %([{ "key": "not_authorized", "messages": ["You are not authorize to access this resource"]}])
    last_response.body.should be_json_eql(errors).at_path('errors')
  end
end
# RSpec.shared_examples "an API patch endpoint" do
#   let(:collection) { described_class.new([7, 2, 4]) }

#   context "initialized with 3 items" do
#     it "says it has three items" do
#       expect(collection.size).to eq(3)
#     end
#   end

#   describe "#include?" do
#     context "with an an item that is in the collection" do
#       it "returns true" do
#         expect(collection.include?(7)).to be_truthy
#       end
#     end

#     context "with an an item that is not in the collection" do
#       it "returns false" do
#         expect(collection.include?(9)).to be_falsey
#       end
#     end
#   end
# end
