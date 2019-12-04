Deface::Override.new :virtual_path  => "users/_form",
                     :name          => "add-back-url-to-user-form",
                     :insert_after  => "erb[loud]:contains('error_messages_for')",
                     :text          => "<%= hidden_field_tag :back_url, params[:back_url] || @back_url if params[:back_url].present? || @back_url.present? %>"
