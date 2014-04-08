class UploadsController < ApplicationController

  # GET /uploads
  # GET /uploads.json
  def index
    @uploads = Upload.all
    
    @upload = Upload.new
    
    if @ipload
    @show = Upload.find(params[:id])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @uploads }
    end
  end


  # POST /uploads
  # POST /uploads.json
  def create
    @upload = Upload.new(params[:upload])

    respond_to do |format|
      if @upload.save
        format.html { redirect_to @upload, notice: 'Upload was successfully created.' }
        format.json { render json: @upload, status: :created, location: @upload }
      else
        format.html { render action: "new" }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

 

  # DELETE /uploads/1
  # DELETE /uploads/1.json
  def destroy
    @upload = Upload.find(params[:id])
    @upload.destroy

    respond_to do |format|
      format.html { redirect_to uploads_url }
      format.json { head :no_content }
    end
  end
end
