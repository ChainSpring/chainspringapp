class Api::V1::MapsController < Api::V1::BaseController
  # before_action :set_node, only: :build_map
  skip_before_action :verify_authenticity_token

  def build_map
    set_node unless @node
    if params[:build_version]
      map = KnowledgeMap.new(@node).send("build_#{params[:build_version]}")
    else
      map = KnowledgeMap.new(@node).build_v4
    end
    response = {map: map, alternative_nodes: @nodes_array}
    render json: response
  end

  def search
    if params[:keyword].present?
      keyword = params[:keyword]
    @nodes_array = []
    begin
      k = Domain.arel_table
      nodes = Domain.where(k[:name].matches("%#{keyword}%")).limit(6)
      @nodes_array += nodes.to_a
      keyword = keyword[0...keyword.length - 1]
      break if keyword.length <= 1 || @nodes_array.length > 2
    end while @nodes_array.length == 0
    @node = @nodes_array.shift
    build_map
    else
      render json: { error: 'Missing keyword ' }, status: :argument_error
    end
  end

  def create_ki
    new_ki = KnowledgeItem.new(ki_params)
    subject = "reference"
    if new_ki.title.blank?
      if @domains
        new_ki.title = @domains.collect(&:name).join('-')
        subject = "topic(s)"
      else
        new_ki = KnowledgeItem.new
      end
    end
    new_ki.domains << @domains if @domains
    if new_ki.save
      redirect_to user_path(current_user), notice: "new #{subject} saved"
    else
      redirect_to user_path(current_user), alert: "new #{subject} could not be saved"
    end
  end
  def update_ki
    user_kis = current_user.knowledge_items
    edited_ki = user_kis.find(params[:newInfo][:object_id])

    if edited_ki.update(ki_params)
      if edited_ki.domains != @domains
        edited_ki.domains = @domains
      end
      redirect_to user_path(current_user), notice: "new KI successfully edited"
    else
      redirect_to user_path(current_user), alert: "KI modifications could not be saved"
    end
  end


  private

  # def get_params
  #   @localization = params[:localization]
  # end
  def ki_params
    # params = {newInfo: {title: "new test reference", user_id: @user.id,  domain_name: @topic.name}}
    safe_params = params.require(:newInfo).permit(:user_id, :title, :kind, :link, :time_needed)

    if params[:newInfo][:domain_name].present?
      domain_names = params[:newInfo][:domain_name].split(/[,;\t]/).map(&:strip)
    else
      domain_names = []
    end
    get_domains(domain_names)
    return safe_params
  end
  def get_domains(domain_names)
    if domain_names.first.present?
      # puts "domain_name : #{domain_name}"
      @domains = []
      domain_names.each do |domain_name|
        domain = Domain.new(name: domain_name)
        @domains << compact_similar(domain)
      end
    else
      # @domains = [Domain.find_or_create_by(name: "Undefined")]
      @domains = nil
    end
  end
  def compact_similar(domain)
    k = Domain.arel_table
    similar_domains = Domain.where(k[:name].matches(domain.name))
    #domain not saved yet so if similar_domains.size > 0 one match already exists
    if similar_domains.size > 0

      total_knowledge_items = similar_domains.map(&:knowledge_items).flatten
      domain = similar_domains.first
      similar_domains -= [domain]
      if similar_domains.count > 0
        similar_domains.each do |redondant_domain|
          redondant_domain.knowledge_items.each do |ki|
            ki.domains << domain
            ki.domains -= [redondant_domain]
          end
        end
        if domain.knowledge_items.count == total_knowledge_items.count
          similar_domains.each{|domain| domain.delete}
        end
      end
    end
    domain.save
    return domain
  end

  def set_node
    node_id = params[:node_id].to_i
     if params[:node_class]
      node_class = Object.const_get params[:node_class].camelize
      @node =  node_class.find(node_id)
    else
      nil
    end
  end

end
