module Searchx
  module SearchHelper
    def search
      @title_ = t(params[:controller].sub(/.+\//,'').singularize.titleize + ' Search')  
      @model, @search_stat = search_(params)
      @lf = instance_eval(@search_stat.labels_and_fields)
      @results_url = 'search_results_' + params[:controller].sub(/.+\//,'') + '_path'
      @erb_code_s = find_config_const('search_params_view', 'searchx')
      @js_erb_code_s = find_config_const(params[:controller].sub(/.+\//,'').singularize + '_search_js_view', params[:controller].sub(/\/.+/, '')) 
      @search_params_partial_erb_code = find_config_const('search_params_partial_view', 'searchx')
    end

    def search_results
      @title_ = t(params[:controller].sub(/.+\//,'').singularize.titleize + ' Search')
      @s_s_results_details =  search_results_(params, @max_pagination)
      #@erb_code = find_config_const(params[:controller].sub(/.+\//,'').singularize + '_index_view', params[:controller].sub(/\/.+/,''))
      @erb_code_s = find_config_const('search_results_view', 'searchx')
      @erb_code = find_config_const(params[:controller].sub(/.+\//,'').singularize + '_index_view', params[:controller].sub(/\/.+/, ''))  #index view code for the engine/module
      remember_link() #for Back to land on search_results page.
      #csv export
      respond_to do |format|
        format.html {@s_s_results_details.models}
        format.csv do
          send_data @s_s_results_details.models.to_csv
          @csv = true
        end
      end
    end
    
    def stats
      @title_ = t(params[:controller].sub(/.+\//,'').singularize.titleize + ' Stats') 
      @model, @search_stat = search_(params)
      @lf = instance_eval(@search_stat.labels_and_fields)
      @results_url = 'stats_results_' + params[:controller].sub(/.+\//,'') + '_path'
      @erb_code_s = find_config_const('stats_params_view', 'searchx')
      @js_erb_code_s = find_config_const(params[:controller].sub(/.+\//,'').singularize + '_search_js_view', params[:controller].sub(/\/.+/, '')) 
      @search_params_partial_erb_code = find_config_const('search_params_partial_view', 'searchx')
    end

    def stats_results
      @title_ = t(params[:controller].sub(/.+\//,'').singularize.titleize + ' Stats') 
      @s_s_results_details =  search_results_(params, @max_pagination)
      @time_frame = eval(@s_s_results_details.time_frame)
      #@erb_code = find_config_const(params[:controller].sub(/.+\//,'').singularize + '_index_view', params[:controller].sub(/\/.+/,''))
      @erb_code_s = find_config_const('stats_results_view', 'searchx')
      @stats_partial_erb_code = find_config_const('stats_partial_index_view', 'searchx')
    end
    
    def acct_summary
      @title_ = t(params[:controller].sub(/.+\//,'').singularize.titleize + ' Summary') 
      @model, @search_stat = search_(params)
      @lf = instance_eval(@search_stat.labels_and_fields)
      @results_url = 'acct_summary_result_' + params[:controller].sub(/.+\//,'') + '_path'
      @erb_code_s = find_config_const('search_params_view', 'searchx')
      @js_erb_code_s = find_config_const(params[:controller].sub(/.+\//,'').singularize + '_search_js_view', params[:controller].sub(/\/.+/, '')) 
      @search_params_partial_erb_code = find_config_const('search_params_partial_view', 'searchx')
    end
    
    def acct_summary_result
      @title_ = t(params[:controller].sub(/.+\//,'').singularize.titleize + ' Summary') 
      @s_s_results_details =  search_results_(params, @max_pagination)
      @erb_code_s = find_config_const(params[:controller].sub(/.+\//,'').singularize + '_acct_summary_view', params[:controller].sub(/\/.+/, ''))
      receivable(@s_s_results_details.models)
      payable(@s_s_results_details.models)
    end
    
    def receivable(models)
      wf = Authentify::AuthentifyUtility.find_config_const(params[:controller].sub(/.+\//,'').singularize + '_acct_receivable_eval', params[:controller].sub(/\/.+/, ''))
      eval(wf) if wf.present?
=begin
      @receivable = {}
      models.each do |m|
        @receivable[m.id.to_s] = InPaymentx::Payment.where(project_id: m.id).sum('paid_amount')
      end
=end
    end
    
    def payable(models)
      wf = Authentify::AuthentifyUtility.find_config_const(params[:controller].sub(/.+\//,'').singularize + '_acct_payable_eval', params[:controller].sub(/\/.+/, ''))
      eval(wf) if wf.present?
=begin
      @payable_approved_unpaid, @payable_paid, @payable_po_unpaid = {}, {}, {}
      models.each do |m|
        @payable_po_unpaid[m.id.to_s] = PurchaseOrderx::Order.where(project_id: m.id).sum('po_total') - PaymentRequestx::PaymentRequest.where(project_id: m.id).where(resource_string: 'purchase_orderx/orders').sum('amount')
        @payable_paid[m.id.to_s] = PaymentRequestx::PaymentRequest.where(project_id: m.id).where(wf_state: :paid).sum('amount')
        @payable_approved_unpaid[m.id.to_s] = PaymentRequestx::PaymentRequest.where(project_id: m.id).where('approved = ? AND wf_state != ?', true, :paid).sum('amount')
      end
=end
    end
    
    #==
    def find_search_stat_info(resource_name)     
      Commonx::SearchStatConfig.where('TRIM(resource_name) = ?', resource_name.strip).last()   
    end

    def search_(params)
      model = params[:controller].singularize.camelize
      model = model.constantize.new() rescue nil
      search_stat = find_search_stat_info(params[:controller].sub('/','_'))
      return model, search_stat
    end
    
    def remember_link()
      previous_url = session[('page' + session[:page_step].to_s).to_sym]
      next_url = form_full_url()
      if next_url != previous_url  #skip if the url is the same.
        session[:page_step] += 1 if session[:page_step].present?
        session[:page_step] = 1 if session[:page_step].blank?
        session[('page' + session[:page_step].to_s).to_sym] = next_url 
      end
    end

    #re-assemble the search url for Back button to land on later.
    def form_full_url()
      url_path = eval(params[:action] + '_' + params[:controller].sub(/.+\//, '') + '_path')
      model = params[:controller].sub(/.+\//, '').singularize
      sub_hash = ''
      params.map do |k, v|
        if sub_hash.present?
          sub_hash += '&' + k.to_s  + '=' + v.to_s if v.present? && k.to_s.include?('_s')
        else
          sub_hash = k.to_s  + '=' + v.to_s if v.present? && k.to_s.include?('_s')
        end if v.is_a?(String)   #saving object will overflow cookie
      end
      return url_path +'?' + sub_hash        #ex, base_part/parts/search?name_s=&category_id=...
    end
   
    class SearchStatsDetails

      def initialize(search_params, col_headers, models, search_stat_result, stat_summary_result, time_frame, search_list_form, search_summary_result) #, col_headers_stat_summary)
        @search_params = search_params
        @col_headers = col_headers
        @models = models
        @search_stat_result = search_stat_result
        @stat_summary_result = stat_summary_result
        @time_frame = time_frame
        @search_list_form = search_list_form
        @search_summary_result = search_summary_result
      end

      def time_frame
        return @time_frame
      end
      
      def search_list_form
        return @search_list_form
      end
      
      def stat_title
        return 'Stats'
      end

      def stat_summary_title
        return 'Stats Summary'
      end

      def search_params
        @search_params
      end

      def col_headers
        @col_headers
      end

      def models
        @models
      end

      def search_stat_result
        @search_stat_result
      end

      def stat_summary_result
        @stat_summary_result
      end
      
      def search_summary_result
        @search_summary_result
      end

    end
  
    def search_results_(params, max_pagination)
      model = params[:controller].singularize.camelize
      controller = params[:controller].sub('/','_')
      #search_stat = SEARCH_STAT_INFO[controller]
      search_stat = find_search_stat_info(controller)
      symbModel = nil #params[:controller].split('/')[-1].singularize.to_sym
      models, search_params  = apply_search_criteria(symbModel, search_stat, params[controller][:model_ar_r], params)
      time_frame = params[:time_frame_s]
      search_stat_result = params[:time_frame_s].present? ? eval(search_stat.stat_function)[time_frame.to_sym] : []
      search_stat_result = [] if search_stat_result.nil?
      stat_summary_result = search_stat.stat_summary_function
      search_summary_result = search_stat.search_summary_function
      col_headers = search_stat.stat_header.split(',').map(&:strip) if search_stat.stat_header #remove space when split
      models = models.page(params[:page]).per_page(max_pagination)
      return SearchStatsDetails.new(search_params, col_headers, models, search_stat_result, stat_summary_result, search_stat.time_frame, search_stat.search_list_form, search_summary_result)
    end
    
    def apply_search_criteria(symbModel, search_stat, models, params)
      search_stats_max_period_year = Authentify::AuthentifyUtility.find_config_const('search_stats_max_period_year').to_i
      search_where_hash = eval(search_stat.search_where)
      search_params_hash = search_stat.search_params.present? ? eval(search_stat.search_params) : {} #for id field which needs to retrieve its value.
      search_params = params[:time_frame_s].present? ? "<%=t('Stats Method') %>" + "=" + I18n.t(params[:time_frame_s]) + ',' : ''
      #SQL
      access_rights, models, has_record_access = Authentify::UserPrivilegeHelper.access_right_finder(params[:action], params[:controller], session[:user_role_ids], nil,nil,nil,nil, session[:user_id] )
      models = eval(search_stat.search_results_period_limit).call()  #apply search_results_period_limit set in db table
      search_where_hash.each do |key, val|
        if params[key].present?
          #the val is a proc that is in the config and has already the "models" variable. 
          #E.g. Proc.new { models.where("projectx_projects.id = ?", params[:project][:project_id_s])}
          models = val.call()
          #param_str = search_params_hash[key].present? ? search_params_hash[key].call() : params[symbModel][key]  #Typeerror if without () into the line below
          search_params +=  "<%=t('" + key.to_s.humanize.titleize[0..-3] + "')%>" + "=" + (search_params_hash[key].present? ? search_params_hash[key].call() : params[key])  + ', '
        end
      end
      return models, search_params
    end

  end
end