class UserPageRelationshipsController < ApplicationController
  # GET /user_page_relationships
  # GET /user_page_relationships.json
  def index
    @user_page_relationships = UserPageRelationship.where(:user_id => 2).all #todo change it back to all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @user_page_relationships }
    end
  end

  # GET /user_page_relationships/1
  # GET /user_page_relationships/1.json
  def show
    @user_page_relationship = UserPageRelationship.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @user_page_relationship }
    end
  end

  # GET /user_page_relationships/new
  # GET /user_page_relationships/new.json
  def new
    @user_page_relationship = UserPageRelationship.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @user_page_relationship }
    end
  end

  # GET /user_page_relationships/1/edit
  def edit
    @user_page_relationship = UserPageRelationship.find(params[:id])
  end

  # POST /user_page_relationships
  # POST /user_page_relationships.json
  def create
    @user_page_relationship = UserPageRelationship.new(params[:user_page_relationship])

    respond_to do |format|
      if @user_page_relationship.save
        format.html { redirect_to @user_page_relationship, notice: 'User page relationship was successfully created.' }
        format.json { render json: @user_page_relationship, status: :created, location: @user_page_relationship }
      else
        format.html { render action: "new" }
        format.json { render json: @user_page_relationship.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /user_page_relationships/1
  # PUT /user_page_relationships/1.json
  def update
    @user_page_relationship = UserPageRelationship.find(params[:id])

    respond_to do |format|
      if @user_page_relationship.update_attributes(params[:user_page_relationship])
        format.html { redirect_to @user_page_relationship, notice: 'User page relationship was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @user_page_relationship.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /user_page_relationships/1
  # DELETE /user_page_relationships/1.json
  def destroy
    @user_page_relationship = UserPageRelationship.find(params[:id])
    @user_page_relationship.destroy

    respond_to do |format|
      format.html { redirect_to user_page_relationships_url }
      format.json { head :no_content }
    end
  end
end
