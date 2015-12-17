class SimplePresenter < Presenter
  expose :name, :email
end

class ExposeWithOtherPresenter < Presenter
  do_not_use_prefixes!

  subjects :user, :comment

  expose :name, with: :user
  expose :user, presenter: SimplePresenter, with: :comment, as: :creator
end

class ExposeWithOneSubjectPresenter < Presenter
  expose :id
  expose :user, presenter: SimplePresenter
  expose :comment, presenter: SimplePresenter
end
