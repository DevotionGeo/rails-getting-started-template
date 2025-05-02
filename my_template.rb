# Rails Application Template based on Getting Started Guide + Rails Auth + RuboCop

# 1. Add Gems
puts "Adding gems..."
# Devise gem removed
gem_group :development, :test do
  gem 'rubocop-rails', require: false
end

after_bundle do
  # Bundle install is implicitly run

  # 2. Generate Product Model & Migration
  puts "Generating Product model..."
  # Use 'decimal' type, precision/scale will be set in migration
  generate(:model, "Product", "name:string", "description:text", "price:decimal")

  # Modify the generated migration to add precision and scale
  # Find the most recent migration file for the products table
  migration_file = Dir.glob("db/migrate/*_create_products.rb").max_by { |f| File.mtime(f) }
  if migration_file
    puts "Updating products migration for price precision/scale..."
    gsub_file migration_file, /t\.decimal :price/, "t.decimal :price, precision: 10, scale: 2"
  else
    puts "Warning: Could not find CreateProducts migration file to update price column."
  end


  # 3. Generate Products Controller & Views
  puts "Generating Products controller (skipping views)..."
  # Add --skip-views to avoid conflicts
  generate(:controller, "Products", "index", "show", "new", "edit", "create", "update", "destroy", "--skip-routes", "--skip-views")

  puts "Creating basic Product views..."
  # Basic index view
  create_file "app/views/products/index.html.erb", <<-HTML
<h1>Products</h1>

<% if current_user %>
  <%= link_to "New Product", new_product_path %>
<% end %>

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Description</th>
      <th>Price</th>
      <th colspan="3"></th>
    </tr>
  </thead>
  <tbody>
    <% Array(@products).each do |product| %>
      <tr>
        <td><%= product.name %></td>
        <td><%= product.description %></td>
        <td><%= number_to_currency(product.price) %></td>
        <td><%= link_to "Show", product %></td>
        <% if current_user %>
          <td><%= link_to "Edit", edit_product_path(product) %></td>
          <td><%= button_to "Destroy", product, method: :delete, data: { turbo_confirm: "Are you sure?" } %></td>
        <% else %>
          <td></td>
          <td></td>
        <% end %>
      </tr>
    <% end %>
  </tbody>
</table>
  HTML

  # Basic show view
  create_file "app/views/products/show.html.erb", <<-HTML
<h1><%= @product.name %></h1>

<p>
  <strong>Description:</strong>
  <%= @product.description %>
</p>

<p>
  <strong>Price:</strong>
  <%= number_to_currency(@product.price) %>
</p>

<%= link_to "Back to products", products_path %>
<% if current_user %>
  | <%= link_to "Edit", edit_product_path(@product) %>
  | <%= button_to "Destroy", @product, method: :delete, data: { turbo_confirm: "Are you sure?" } %>
<% end %>
  HTML

  # Basic form partial
  create_file "app/views/products/_form.html.erb", <<-HTML
<%= form_with(model: product) do |form| %>
  <% if product.errors.any? %>
    <div style="color: red">
      <h2><%= pluralize(product.errors.count, "error") %> prohibited this product from being saved:</h2>
      <ul>
        <% product.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :name %><br>
    <%= form.text_field :name %>
  </div>

  <div>
    <%= form.label :description %><br>
    <%= form.text_area :description %>
  </div>

  <div>
    <%= form.label :price %><br>
    <%= form.number_field :price, step: 0.01 %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
  HTML

  # Basic new view
  create_file "app/views/products/new.html.erb", <<-HTML
<h1>New Product</h1>

<%= render "form", product: @product %>

<br>

<div>
  <%= link_to "Back to products", products_path %>
</div>
  HTML

  # Basic edit view
  create_file "app/views/products/edit.html.erb", <<-HTML
<h1>Editing Product</h1>

<%= render "form", product: @product %>

<br>

<div>
  <%= link_to "Show this product", @product %> |
  <%= link_to "Back to products", products_path %>
</div>
  HTML

  # 4. Setup Routes
  puts "Setting up routes..."
  route "root 'products#index'"
  route "resources :products"
  # Auth routes will be added by the generator

  # 5. Install and Configure Rails Authentication
  puts "Setting up Rails Authentication..."
  generate :authentication # Use the built-in generator

  # Give Rails a moment to generate the authentication files
  sleep 1

  # Modify the user migration to use 'email' instead of 'email_address'
  puts "Updating user migration to use 'email' field..."
  user_migration_file = Dir.glob("db/migrate/*_create_users.rb").max_by { |f| File.mtime(f) }
  if user_migration_file
    gsub_file user_migration_file, /t\.string :email_address/, "t.string :email"
    gsub_file user_migration_file, /add_index :users, :email_address/, "add_index :users, :email"
  else
    puts "Warning: Could not find CreateUsers migration file to update email field."
  end

  # Modify the User model to normalize :email instead of :email_address
  puts "Updating User model to normalize 'email' field..."
  gsub_file "app/models/user.rb", /normalizes :email_address/, "normalizes :email"

  # Complete replacement of the session form view to ensure field names are correct
  puts "Replacing sessions form to use 'email' field consistently..."
  remove_file "app/views/sessions/new.html.erb"
  create_file "app/views/sessions/new.html.erb", <<-HTML
<h1>Sign In</h1>

<%= form_with url: session_path do |form| %>
  <div>
    <%= form.label :email %><br>
    <%= form.email_field :email, autofocus: true, required: true %>
  </div>

  <div>
    <%= form.label :password %><br>
    <%= form.password_field :password, required: true %>
  </div>

  <div>
    <%= form.submit "Sign in" %>
  </div>
<% end %>

<div>
  <%= link_to "Forgot your password?", new_password_path %> |
  <%= link_to "Sign up", new_user_path %>
</div>
  HTML

  # Update SessionsController to use email instead of email_address
  puts "Updating SessionsController to use 'email' parameter..."
  gsub_file "app/controllers/sessions_controller.rb", /params\.permit\(:email_address, :password\)/,
            "params.permit(:email, :password)"

  # Also update the user lookup in authenticate_by if needed
  gsub_file "app/controllers/sessions_controller.rb", /User\.authenticate_by\(email_address:/,
            "User.authenticate_by(email:"

  # Update SessionsController to add success message after login
  puts "Updating SessionsController to add login success message..."

  # Look for the redirect_to after_authentication_url line in SessionsController and add notice
  gsub_file "app/controllers/sessions_controller.rb",
            /redirect_to after_authentication_url/,
            "redirect_to after_authentication_url, notice: \"Signed in successfully!\""

  # Create sign up functionality that works with the existing routes
  puts "Setting up user registration functionality..."

  # Check the actual routes generated by the authentication system
  routes_content = File.read("config/routes.rb")

  # Create a controller for handling user registrations that matches auth generator's routes
  create_file "app/controllers/users_controller.rb", <<-RUBY
class UsersController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      redirect_to new_session_path, notice: "Account created successfully. Please sign in."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:email, :password, :password_confirmation)
    end
end
  RUBY

  # Create a registration form view
  create_file "app/views/users/new.html.erb", <<-HTML
<h1>Sign Up</h1>

<%= form_with(model: @user, url: users_path) do |form| %>
  <% if @user.errors.any? %>
    <div style="color: red">
      <h2><%= pluralize(@user.errors.count, "error") %> prohibited this user from being saved:</h2>
      <ul>
        <% @user.errors.each do |error| %>
          <li><%= error.full_message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= form.label :email %><br>
    <%= form.email_field :email %>
  </div>

  <div>
    <%= form.label :password %><br>
    <%= form.password_field :password %>
  </div>

  <div>
    <%= form.label :password_confirmation %><br>
    <%= form.password_field :password_confirmation %>
  </div>

  <div>
    <%= form.submit "Sign up" %>
  </div>
<% end %>

<div>
  <%= link_to "Back to sign in", new_session_path %>
</div>
  HTML

  # Ensure there's a route for users
  unless routes_content.include?("resources :users")
    route "resources :users, only: [:new, :create]"
  end

  # Insert the layout with correct path helpers for user registration
  puts "Updating application layout with proper authentication links..."

  # Remove the previous insert_into_file call for application.html.erb
  gsub_file "app/views/layouts/application.html.erb", /<p class="notice">.*?<hr>/m, ""

  # Insert updated layout with better path handling
  insert_into_file "app/views/layouts/application.html.erb", before: "<%= yield %>" do
    <<-HTML
    <p class="notice"><%= notice %></p>
    <p class="alert"><%= alert %></p>

    <nav>
      <%= link_to "Home", root_path %> |
      <% if Current.user %>
        Logged in as <strong><%= Current.user.email %></strong>.
        <% begin %>
          <%= link_to "Edit profile", edit_identity_email_path %> |
        <% rescue NameError, NoMethodError %>
          <% # Fall back if the path helper isn't available %>
        <% end %>
        <%= button_to "Log out", session_path(Current.session), method: :delete %>
      <% else %>
        <%= link_to "Sign up", new_user_path %> |
        <%= link_to "Sign in", new_session_path %>
      <% end %>
    </nav>
    <hr>
    HTML
  end

  # Update Authentication concern to work with email field if needed
  puts "Ensuring Authentication concern works with 'email' field..."
  authentication_file = "app/controllers/concerns/authentication.rb"
  if File.exist?(authentication_file)
    gsub_file authentication_file, /email_address/, "email" # Replace all occurrences
  end

  # Overwrite Current model to ensure correct user setting via session
  puts "Ensuring Current model is correctly defined..."
  create_file "app/models/current.rb", <<-RUBY, force: true
# filepath: app/models/current.rb
# Standard Current model for Rails authentication
class Current < ActiveSupport::CurrentAttributes
  attribute :user, :session, :request_id, :user_agent, :ip_address

  # Example method to reset attributes between requests
  # resets { Time.zone = nil }

  # Setter for session attribute, which also sets the user
  def session=(session)
    super
    self.user = session&.user # Use safe navigation
  end
end
  RUBY

  # Ensure helper_method declarations in Authentication concern
  puts "Ensuring authentication helper methods are available..."
  if File.exist?(authentication_file)
    content = File.read(authentication_file)

    # Ensure helper_method :authenticated? exists
    unless content.match?(/helper_method\s+.*:authenticated\?/)
      insert_into_file authentication_file, after: /included do\s*\n/ do
        "    helper_method :authenticated?\n"
      end
    end

    # Ensure helper_method :current_user exists
    unless content.match?(/helper_method\s+.*:current_user/)
      insert_into_file authentication_file, after: /included do\s*\n/ do
        "    helper_method :current_user\n"
      end
    end

    # Ensure current_user method definition exists
    unless content.match?(/def current_user\s*Current\.user\s*end/)
      insert_into_file authentication_file, before: /\nend\n\z/ do # Before the final 'end'
        <<-RUBY

  def current_user
    Current.user
  end
        RUBY
      end
    end
  end


  # Insert simplified layout with authenticated? helper (Ensure this is the final layout update)
  puts "Updating application layout with authenticated? helper..."

  # Remove any previous nav/flash sections added by this template to avoid duplication
  gsub_file "app/views/layouts/application.html.erb", /<p class="notice">.*?<hr>/m, ""

  # Insert updated layout with authenticated? helper which is more reliable
  insert_into_file "app/views/layouts/application.html.erb", before: "<%= yield %>" do
    <<-HTML
    <p class="notice"><%= notice %></p>
    <p class="alert"><%= alert %></p>

    <nav>
      <%= link_to "Home", root_path %> |
      <% if authenticated? %>
        Logged in as <strong><%= current_user.email %></strong>.
        <%# Use respond_to? for checking path helper existence %>
        <% if respond_to?(:edit_identity_email_path) %>
          <%= link_to "Edit profile", edit_identity_email_path %> |
        <% end %>
        <%= button_to "Log out", session_path(Current.session), method: :delete %>
      <% else %>
        <%= link_to "Sign up", new_user_path %> |
        <%= link_to "Sign in", new_session_path %>
      <% end %>
    </nav>
    <hr>
    HTML
  end

  # 6. Implement Controller Logic & Authentication
  puts "Implementing ProductsController logic and authentication..."

  # Define the complete controller content
  controller_content = <<-RUBY
class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show edit update destroy ]
  # Use allow_unauthenticated_access as per Rails 8 guide
  allow_unauthenticated_access only: %i[ index show ]

  # GET /products or /products.json
  def index
    @products = Product.all
  end

  # GET /products/1 or /products/1.json
  def show
  end

  # GET /products/new
  def new
    @product = Product.new
  end

  # GET /products/1/edit
  def edit
  end

  # POST /products or /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save
        format.html { redirect_to product_url(@product), notice: "Product was successfully created." }
        format.json { render :show, status: :created, location: @product }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1 or /products/1.json
  def update
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to product_url(@product), notice: "Product was successfully updated." }
        format.json { render :show, status: :ok, location: @product }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1 or /products/1.json
  def destroy
    @product.destroy!

    respond_to do |format|
      format.html { redirect_to products_url, notice: "Product was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(:name, :description, :price)
    end
end
  RUBY

  # Overwrite the generated controller file with the full content
  create_file "app/controllers/products_controller.rb", controller_content, force: true


  # 7. Populate Seeds
  puts "Populating seed data..."
  remove_file "db/seeds.rb"
  create_file "db/seeds.rb", <<-RUBY
# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "Seeding database..."

# Create default user using Rails 8 Auth structure
begin
  User.create!(email: 'someone@example.com', password: 'secret123', password_confirmation: 'secret123')
  puts "Created default user 'someone@example.com'"
rescue ActiveRecord::RecordInvalid
  # Simplified message to avoid using the exception variable 'e'
  puts "Default user 'someone@example.com' could not be created (likely validation error or already exists)."
rescue ActiveRecord::RecordNotUnique
  puts "Default user 'someone@example.com' already exists."
end


# Create sample products
Product.find_or_create_by!(name: 'Fancy Gadget') do |product|
  product.description = 'A really fancy gadget you definitely need.'
  product.price = 99.99
  puts "Created product: Fancy Gadget"
end

Product.find_or_create_by!(name: 'Basic Widget') do |product|
  product.description = 'Does the job, nothing more.'
  product.price = 15.50
  puts "Created product: Basic Widget"
end

Product.find_or_create_by!(name: 'Super Gizmo') do |product|
  product.description = 'The best gizmo in the market!'
  product.price = 149.00
  puts "Created product: Super Gizmo"
end

puts "Seeding finished."
  RUBY

  # 8. Configure RuboCop
  puts "Configuring RuboCop..."
  create_file ".rubocop.yml", <<-YAML
# This is the configuration used by RuboCop linters.
# More info: https://docs.rubocop.org/rubocop/configuration.html

require:
  - rubocop-rails

AllCops:
  NewCops: enable # Adopt new cops as they become available
  Exclude:
    - 'bin/*'
    - 'db/schema.rb'
    - 'db/migrate/*'
    - 'node_modules/**/*'
    - 'vendor/**/*'
    - 'tmp/**/*'
    # - 'config/initializers/devise.rb' # Removed devise exclusion

Style/Documentation:
  Enabled: false # Generally good, but can be noisy for new projects

Style/FrozenStringLiteralComment:
  Enabled: false # Rails manages this

Rails/SkipsModelValidations:
  Enabled: false # Allow skipping validations in seeds/specific cases if needed

Metrics/BlockLength:
  Exclude:
    - 'config/routes.rb'
    - 'config/environments/*'
    - 'lib/tasks/*'
    - 'spec/**/*' # Allow longer blocks in tests
    - 'app/controllers/concerns/authentication.rb' # Auth generator file can be long

Metrics/MethodLength:
  Max: 15

Metrics/AbcSize:
  Max: 20
  YAML

  # 9. Run Migrations and Seed
  puts "Running database migrations..."
  rails_command "db:migrate"

  puts "Seeding database..."
  rails_command "db:seed"

  # 10. Run RuboCop Auto-correct
  puts "Running RuboCop auto-correct..."
  run "bundle exec rubocop -A --fail-level A || true" # Run autocorrect, ignore exit status if no offenses

  # 11. Initialize Git Repository
  puts "Initializing Git repository..."
  git :init
  git add: "."
  # Exclude log and tmp files commonly ignored
  append_to_file ".gitignore", <<-IGNORE

# Ignore logfiles and tempfiles.
/log/*
!/log/.keep
/tmp/*
!/tmp/.keep
  IGNORE

  git commit: "-m 'Initial commit: Rails app generated with custom template (Rails Auth)'"

  puts "\nTemplate application finished!"
  puts "Default user created: someone@example.com / secret123"
  puts "Run 'bin/rails server' and visit http://localhost:3000"

end
