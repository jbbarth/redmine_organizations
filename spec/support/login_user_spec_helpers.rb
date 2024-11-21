require "spec_helper"

def log_user(login, password)
  visit '/my/page'
  expect(current_path).to eq '/login'

  click_on("ou s'authentifier par login / mot de passe")

  within('#login-form form') do
    fill_in 'username', with: login
    fill_in 'password', with: password
    find('input[name=login]').click
  end
  expect(current_path).to eq '/my/page'
end