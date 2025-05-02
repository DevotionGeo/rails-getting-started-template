# Rails Starter Template

This repository contains a Rails application template (`my_template.rb`) designed to quickly set up a new Rails project based on the official "Getting Started" guide, using the built-in **Rails 8 authentication generator** and code linting (RuboCop).

## Features Included

The generated Rails application will include:

*   **Product CRUD:** A `Product` model, controller, and views for basic Create, Read, Update, Delete operations.
*   **User Authentication:** Integration using the `bin/rails generate authentication` command for user sign-up, sign-in, sign-out, password reset, and email verification.
*   **Basic Authorization:** Only logged-in users can create, edit, or delete products. All users can view products (index and show pages).
*   **Seed Data:**
    *   A default user: `someone@example.com` with password `secret123`.
    *   Sample products.
*   **RuboCop:** Configured with `rubocop-rails` for code style enforcement. The template runs an initial auto-correct.
*   **Git Initialization:** Initializes a Git repository and creates an initial commit.

## Using the Template

To generate a new Rails application using this template:

1.  **Install Rails:** Make sure you have Rails installed (`gem install rails`).
2.  **Run `rails new`:** Open your terminal and run the `rails new` command. You must provide an application name (e.g., `store`). Use the `-m` flag followed by the raw URL of your template file. Replace 'store' with the name you want for your application if different


    ```bash
    rails new store -m https://raw.githubusercontent.com/DevotionGeo/rails-getting-started-template/refs/heads/main/my_template.rb
    ```

3.  **Start the Server:** After the process completes, navigate into your new application directory (`cd store`), run `bin/rails server`, and visit `http://localhost:3000` in your browser.

You should see the product index page. You can sign up for a new account or sign in using the default user (`someone@example.com` / `secret123`) to manage products.
