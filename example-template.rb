#run "echo TODO > README"

plugin "serialist", :git => "http://github.com/bbenezech/serialist.git"
generate :scaffold, "article title:string"
generate :serialist, "SerialistMigration", :articles, :slug
rake "db:migrate"

git :init
file ".gitignore", <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END

file "app/views/articles/new.html.erb", <<-END
<h1>New article</h1>

<% form_for(@article) do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form"
<% end %>

<%= link_to 'Back', articles_path %>
END

file "app/views/articles/edit.html.erb", <<-END
<h1>Editing article</h1>

<% form_for(@article) do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form"
<% end %>

<%= link_to 'Show', @article %> |
<%= link_to 'Back', articles_path %>
END


file "app/views/articles/_form.html.erb", <<-END
  <p>
    <%= f.label :title %><br />
    <%= f.text_field :title %>
  </p>
  <p>
    <%= f.label :string_test %><br />
    <%= f.text_field :string_test %>
  </p>
  <p>
    <%= f.label :text_test %><br />
    <%= f.text_area :text_test %> 
  </p>
  <p>
    <%= f.label :select_test %><br />
    <%= f.select :select_test %>
  </p>
  <p>
    <%= f.label :checkbox_test %><br />
    <%= f.checkbox :checkbox_test %>
  </p>
  <p>
    <%= f.submit 'Update' %>
  </p>
END


file "app/views/articles/show.html.erb", <<-END
<p>
  <b>Title:</b>
  <%=h @article.title %>
</p>
<p>
  <b>string_test:</b>
  <%=h @article.string_test %>
</p>
<p>
  <b>text_test:</b>
  <%=h @article.text_test %>
</p>
<p>
  <b>select_test:</b>
  <%=h @article.select_test %>
</p>
<p>
  <b>checkbox_test:</b>
  <%=h @article.checkbox_test %>
</p>


<%= link_to 'Edit', edit_article_path(@article) %> |
<%= link_to 'Back', articles_path %>
END



file "app/models/article.rb", <<-END
  class Article < ActiveRecord::Base
    serialist :slug
  end
END
run "rm public/index.html"
route "map.root :controller => 'articles'"

git :add => ".", :commit => "-m 'initial commit'"

run "echo Application ready"

