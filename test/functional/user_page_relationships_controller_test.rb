require 'test_helper'

class UserPageRelationshipsControllerTest < ActionController::TestCase
  setup do
    @user_page_relationship = user_page_relationships(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_page_relationships)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user_page_relationship" do
    assert_difference('UserPageRelationship.count') do
      post :create, user_page_relationship: { fb_created_time: @user_page_relationship.fb_created_time, page_id: @user_page_relationship.page_id, relationship_type: @user_page_relationship.relationship_type, user_id: @user_page_relationship.user_id }
    end

    assert_redirected_to user_page_relationship_path(assigns(:user_page_relationship))
  end

  test "should show user_page_relationship" do
    get :show, id: @user_page_relationship
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @user_page_relationship
    assert_response :success
  end

  test "should update user_page_relationship" do
    put :update, id: @user_page_relationship, user_page_relationship: { fb_created_time: @user_page_relationship.fb_created_time, page_id: @user_page_relationship.page_id, relationship_type: @user_page_relationship.relationship_type, user_id: @user_page_relationship.user_id }
    assert_redirected_to user_page_relationship_path(assigns(:user_page_relationship))
  end

  test "should destroy user_page_relationship" do
    assert_difference('UserPageRelationship.count', -1) do
      delete :destroy, id: @user_page_relationship
    end

    assert_redirected_to user_page_relationships_path
  end
end
