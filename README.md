# Easyhooks - Webhooks made easy

Easyhooks is a ruby gem created to handle webhooks for Rails ActiveRecord instances. Simple, easy and fast.
You can use it to create webhooks for your models, and then use them to send data to your clients.

## Requirements

- Ruby 3.0 or newer
- Rails 6.1 or newer (including Rails 7.0)

## Installation

Include the gem in your Gemfile and run `bundle` to install it:

```ruby
gem 'easyhooks'
```

This step is not required if you don't want to store your hooks configuration in the database, but it's recommended.

```shell
rails g easyhooks:migration
rails db:migrate
```

## Usage

### Defining the easiest hook

```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved do
      action :my_first_action, endpoint: 'https://example.com'
    end
  end
end
```

The example above it's the simplest use. It will create a trigger called `approved` for the `User` model. Whenever a _user_ is **created**, **updated** or **deleted**,
the trigger `approved` dispatches an **ActiveJob** called `PostProcessor` to asynchronously send a **POST** request to the endpoint `https://example.com` with the following payload:

```json
{
  "object": "User",
  "action": "my_first_action",
  "trigger": {
    "name": "approved",
    "event": "CREATE"
  },
  "data": {
    "id": 1
  }
}
```

Easy, no? Let's understand how everything works and see how to customize it even more.

### Trigger

A trigger is a way to define when a webhook should be dispatched. It can be defined by the following options:
* `:on` - Defines the events that will trigger the webhook. It can be `:create`, `:update` or `:destroy`. Defaults to `[:create, :update, :destroy]`.
* `:only` - Defines the attributes that will trigger the webhook. It can be a single attribute or an array of attributes. Defaults to `nil` (or any model changes). Example: `only: :name` or `only: [:name, :email]`.

**Note:** `:only` works only for `:update` events.

Example:

```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved, on: :update, only: :name do
      action :my_first_action, endpoint: 'https://example.com'
    end
  end
end
```

Whenever in your codebase a `User` is updated and the `name` attribute is changed, the trigger `approved` will dispatch the action `my_first_action`.

### Action

An action is a way to define what should be done when a webhook is dispatched. It can be defined by the following options:
* `:endpoint` - Defines the endpoint that will receive the webhook data. It must be a valid URL.
* `:method` - Defines the HTTP method that will be used to send the webhook. It can be `:get`, `:post`, `:put`, `:patch` or `:delete`. Defaults to `:post`.
* `:headers` - Defines the headers that will be sent with the webhook. It must be a hash. Defaults to `{ 'Content-Type': 'application/json' }`.
* `:auth` - Defines the authentication that will be used to send with the webhook `Authorization` header. Is must be a string. Defaults to `nil`. Example: `Basic YWRtaW46cGFzc3dvcmQ=`.

Example:

```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved do
      action :my_first_action, endpoint: 'https://example.com', method: :put, headers: { 'X-Easy': 'Easyhooks' }, auth: 'Basic YWRtaW46cGFzc3dvcmQ='
    end
  end
end
```

You can also define multiple actions for a single trigger:

```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved do
      action :my_first_action, endpoint: 'https://example.com/first', method: put
      action :my_second_action, endpoint: 'https://example.com/second', method: post
    end
  end
end
```

### Customizing the Payload

The payload is the data that will be sent to the endpoint. It can be defined by the following options in any easyhooks block like `trigger`, `action` or even `easyhooks`:
* `:payload` - Defines the payload that will be sent to the endpoint. It must be a symbol or a proc. Defaults to `{ id: model.id }`.

**Note:** If you define a payload in a `trigger` block, it will be used for all actions. If you define a payload in an `action` block, it will be used only for that action.

Example:

```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved do
      action :my_first_action, endpoint: 'https://example.com', payload: :my_payload
    end
  end

  def my_payload
    { id: id, name: name }
  end
end
```
JSON Payload:
```json
{
  "object": "User",
  "action": "my_first_action",
  "trigger": {
    "name": "approved",
    "event": "CREATE"
  },
  "data": {
    "id": 1,
    "name": "John Doe"
  }
}
```

### Adding conditions

You can add conditions to your triggers and actions. It can be defined by the following options:
* `:if` - Defines a condition that will be evaluated before dispatching the webhook. It must be a symbol or a proc. Defaults to `nil`.

**Note:** If you define a condition in a `trigger` block, it will be used for all actions. If you define a condition in an `action` block, it will be used only for that action.

Example:

```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved, if: :my_condition do
      action :my_first_action, endpoint: 'https://example.com'
    end
  end

  def my_condition
    name == 'John Doe'
  end
end
```

### Accessing the webhook response data

You can access the webhook response data in your codebase. This will be useful if you want to do something with the response, like logging it.

**Note:** This callback will be called only if the webhook is successfully sent. Meaning that, if any error occurs while evaluating the webhook, this callback will not be called.
For failure callbacks, you can use the `:on_fail` option.

**Note 2:** The response object is an instance of [Net::HTTPResponse](https://ruby-doc.org/stdlib-3.0.0/libdoc/net/http/rdoc/Net/HTTPResponse.html).

Example:

```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved do
      action :my_first_action, endpoint: 'https://example.com' do |response|
        puts response.code
        puts response.body
      end
    end
  end
end
```

### Handling webhook failures

You can handle webhook failures in your codebase. This will be useful let's say if the endpoint is down and you want to retry the webhook later.
You can define a `:on_fail` callback (symbol or proc) in any easyhooks block like `trigger` or `action`:
```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved do
      action :my_first_action, endpoint: 'https://example.com', on_fail: :my_callback
    end
  end

  def my_callback
    # Do something
  end
end
```

### Global configuration

Defining endpoints, headers and auth for each action can be a little bit annoying. You can define a global configuration for all actions in your codebase.
There is three ways to do that:
* Using the `easyhooks` block
* Using an YAML file
* Using the database

#### Using the `easyhooks` block

You can define a global configuration for all actions in your codebase using the `easyhooks` block:

```ruby
class User < ActiveRecord::Base
  easyhooks endpoint: 'https://example.com', auth: 'Bearer token' do
    trigger :approved do
      action :my_first_action, if: :my_condition
      action :my_second_action, if: :my_second_condition
    end
  end
end
```

**Note:** Easyhooks prioritizes the configuration defined in the `action` block over the configuration defined in the `easyhooks` block:
* Order of priority: `action` > `trigger` > `easyhooks` > `yaml` > `database`.

Example:
```ruby
class User < ActiveRecord::Base
  easyhooks endpoint: 'https://example.com' do
    trigger :approved do
      action :my_first_action, method: :put
      action :my_second_action
    end
  end
end
```

In the example above, the `my_first_action` will be sent using the `PUT` method, while the `my_second_action` will be sent using the `POST` method.
You can combine any number of configurations in your codebase and Easyhooks handle.

#### Using an YAML file

You can define a global configuration for all actions in your codebase using an YAML file:

```yaml
# config/easyhooks.yml
development:
  classes:
    User:
      endpoint: 'https://example.com'
      method: :post
      auth: 'Bearer token'
      headers:
        X-Easy: Easyhooks
  triggers:
    approved:
      endpoint: 'https://example.com'
      method: :patch
  actions:
    my_first_action:
      endpoint: 'https://example.com'
      method: :put
```

In the example above, we start configuring the hooks by environment.
An `action` should have a unique name and can be shared between classes. Same for `triggers`.
A `class` can have multiple trigger/actions and you can define a single configuration by class.

**Note:** The priority of the configurations defined in the YAML file is the same as mentioned before:
* Order of priority: `action` > `trigger` > `easyhooks` > `yaml` > `database`.

#### Using the database (Stored configuration)

You can define a global configuration for everything in your codebase using the database. For that you will need
to execute the migration generator and run the migration:

```shell
rails g easyhooks:migration
rails db:migrate
```

Define your models and hooks, but make sure to use the `:stored` option in the `easyhooks` block:
```ruby
class User < ActiveRecord::Base
  easyhooks :stored do
    trigger :approved do
      action :my_first_action
    end
  end
end
```
Then, store the configuration in the database using the `Easyhooks::Store` model. Open the rails console and run:
```ruby
  stored_action = Easyhooks::Store.create!(context: 'actions', name: 'my_first_action', endpoint: 'https://example.com', method: :put)
  stored_action.add_headers({ 'X-Easy': 'Easyhooks' })
  stored_action.add_auth('Bearer', 'token')
```

Using the database store will allow you to change the configuration without the need to restart your application, which
is pretty useful, let`s say, if you want to change the endpoint of a webhook that is broken, or the auth token expired.

The `context` attribute can be `actions`, `triggers` or `classes`. 
The `name` attribute is the name of the action, trigger or class.

Here you can also override the configurations using the priority order mentioned before:
```ruby
class User < ActiveRecord::Base
  easyhooks :stored do
    trigger :approved do
      action :my_first_action
      action :my_second_action, method: :patch
    end
  end
end
```

You can also use the type `:stored` for blocks like `trigger` and `action`, and combine multiple rules:
```ruby
  Easyhooks::Store.create!(context: 'triggers', name: 'approved', method: :patch, endpoint: 'https://example.com/users')
```
```ruby
class User < ActiveRecord::Base
  easyhooks do
    trigger :approved, type: :stored do
      action :my_first_action, payload: :my_payload
      action :another_action, method: :post
    end
    trigger :deleted, on: :destroy, payload: :my_other_payload, if: :condition do
      action :my_second_action, endpoint: 'https://example.com/users/deleted'
    end
  end
end
```

## Conclusion
You can combine all the options mentioned above to create your own webhooks. Easyhooks is flexible and easy to use.
Be creative and have fun!

## Contributing

Bug reports and pull requests are welcome. This project is intended to be a safe, welcoming space for collaboration.

## Future improvements

- Add option to temporarily disable a trigger, action or class hook
- Add option to retry a webhook if it fails
- Add option to define a timeout for the webhook
- Rails generator to create database stored hooks
- Rails generator to create YAML stored hooks


## License

Apache License, Version 2.0.
See [LICENSE](https://apache.org/licenses/LICENSE-2.0.txt) for details.

Copyright (c) 2023-2023 [Thiago Bonfante](https://github.com/thiagobonfante)