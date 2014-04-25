require 'test_helper'

class PredictsControllerTest < ActionController::TestCase
  setup do
    @predict = predicts(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:predicts)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create predict" do
    assert_difference('Predict.count') do
      post :create, predict: {  }
    end

    assert_redirected_to predict_path(assigns(:predict))
  end

  test "should show predict" do
    get :show, id: @predict
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @predict
    assert_response :success
  end

  test "should update predict" do
    put :update, id: @predict, predict: {  }
    assert_redirected_to predict_path(assigns(:predict))
  end

  test "should destroy predict" do
    assert_difference('Predict.count', -1) do
      delete :destroy, id: @predict
    end

    assert_redirected_to predicts_path
  end
end
