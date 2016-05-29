module Upholsterer
  class Base
    # Define how many subjects this presenter will receive.
    # Each subject will create a private method with the same name.
    #
    # The first subject name will be used as default, thus isn't required as <tt>:with</tt>
    # option on the Upholsterer::Base.expose method.
    #
    #   class CommentPresenter < Presenter
    #     subjects :comment, :post
    #     expose :body                  # will expose comment.body through CommentPresenter#body
    #     expose :title, :with => :post # will expose post.title through CommentPresenter#post_title
    #   end
    #
    # Subjects can be accessed by a private name with the same name.
    # So the above subjects can be accessed internally by the methods +comment+ and +post+.
    #
    # If you're not setting any special name, then you can access it using the +subject+ method.
    #

    attr_reader :subject

    def self.subjects(*names)
      @subjects ||= [:subject]

      unless names.empty?
        @subjects = names
        attr_reader *names
        private *names
        public :subject
      end

      @subjects
    end

    class << self
      alias_method :subject, :subjects
    end

    # Propagate inherited subjects and attributes.
    #
    def self.inherited(child)
      child.subjects(*subjects)
      attributes.each_value do |attr_name, options|
        child.expose(attr_name, options)
      end
      child.do_not_use_prefixes! if do_not_use_prefixes?
    end

    # Store all attributes and options that have been exposed.
    #
    #   class UserPresenter < Presenter
    #     expose :name
    #     expose :street, with: "address"
    #   end
    #
    #   UserPresenter.attributes
    #   #=> {
    #   #=>   name: [:name, {}],
    #   #=>   address_street: [:street, {with: "address"}]
    #   #=> }
    #
    def self.attributes
      @attributes ||= {}
    end

    def self.do_not_use_prefixes!
      @do_not_use_prefixes = true
    end

    def self.do_not_use_prefixes?
      @do_not_use_prefixes
    end

    # This method will return a presenter for each item of collection.
    #
    #   users = UserPresenter.map(User.all)
    #
    # If your presenter accepts more than one subject, you can provided
    # them as array of parameters.
    #
    #   comments = CommentPresenter.map([[comment, post]])
    #
    def self.map(collection)
      collection.map {|items| new(*items) }
    end

    # The list of attributes that will be exposed.
    #
    #   class UserPresenter < Presenter
    #     expose :name, :email
    #   end
    #
    # You can also expose an attribute from a composition.
    #
    #   class CommentPresenter < Presenter
    #     expose :body, :created_at
    #     expose :name, :with => :user
    #     expose :name, :as => :author
    #   end
    #
    # The presenter above will expose the methods +body+, +created_at+, and +user_name+.
    # Additionaly, it will create an alias called +author+ to the +name+ attribute.
    #
    def self.expose(*attrs, &block)
      options = attrs.pop if attrs.last.kind_of?(Hash)
      options ||= {}

      container = options.fetch(:with, nil)
      method_prefix = container if options.fetch(:prefix, !do_not_use_prefixes?)
      presenter = options.fetch(:presenter, nil)

      if block_given? and container.present?
        wrapper_method = define_block_handler(attrs, container, presenter, &block)
      end

      attrs.each do |attr_name|
        define_expose_method(attr_name, options, method_prefix, container, wrapper_method, presenter, &block)
      end
    end

    # It assigns the subjects.
    #
    #   user = UserPresenter.new(User.first)
    #
    # You can assign several subjects if you want.
    #
    #   class CommentPresenter < Presenter
    #     subject :comment, :post
    #     expose :body
    #     expose :title, :with => :post
    #   end
    #
    #  comment = CommentPresenter.new(Comment.first, Post.first)
    #
    # If the :with option specified to one of the subjects, then the default subject is bypassed.
    # Otherwise, it will be proxied to the default subject.
    #
    def initialize(*subjects)
      self.class.subjects.each_with_index do |name, index|
        instance_variable_set("@#{name}", subjects[index])
      end
    end

    def to_param(*params)
      @subject.to_param(*params)
    end

    private

    def self.define_block_handler(attrs, container, presenter, &block)
      wrapper_method = "#{ attrs.join('_') }_wrapper"
      wrapper_instance_variable = "@#{ wrapper_method }"

      define_method wrapper_method do
        unless instance_variable_defined?(wrapper_instance_variable)
          if respond_to?(container)
            object_container = public_send(container)
          else
            object_container = subject.public_send(container)
          end

          wrapper = instance_eval(&block).new(object_container)

          instance_variable_set(wrapper_instance_variable, wrapper)
        end

        value = instance_variable_get(wrapper_instance_variable)
        decorate_with_presenter(value, presenter)
      end

      private wrapper_method

      return wrapper_method
    end

    def self.define_expose_method(attr_name, options, method_prefix, container, wrapper_method, presenter, &block)
      if options.fetch(:serializable, false)
        attributes[attr_name] = [attr_name, options]
      else
        method_name = [
          method_prefix,
          options.fetch(:as, attr_name)
        ].compact.join('_')

        attributes[method_name.to_sym] = [attr_name, options]

        if block_given? and container.present?
          delegate attr_name, to: wrapper_method, prefix: !!method_prefix
        else
          define_method method_name do |&block|
            value = proxy_message(container, attr_name, &block)
            decorate_with_presenter(value, presenter)
          end
        end
      end
    end

    def proxy_message(subject_name, method, &block)
      if subject_name.blank? # expose :id
        subject = send(self.class.subjects.first)
      elsif self.class.subjects.include?(subject_name) # expose :id, with: :user, when :user is one of subjects or custom getter
        subject = send(subject_name)
      else
        subject = send(self.class.subjects.first).send(subject_name)# expose :id, with: :user
      end

      subject.respond_to?(method) ? subject.__send__(method, &block) : nil
    end

    def decorate_with_presenter(value, presenter)
      if value.present? and presenter
        if value.is_a? Array
          presenter.map(value)
        else
          presenter.new(value)
        end
      else
        value
      end
    end
  end
end
