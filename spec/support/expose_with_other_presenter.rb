class SimplePresenter < Presenter
  expose :name, :email
end

class ExposeWithOtherPresenter < Presenter
  subjects :user, :comment

  expose :name, with: :user
  expose :user, presenter: SimplePresenter, with: :comment, as: :creator, prefix: false
end

class ExposeWithOneSubjectPresenter < Presenter
  expose :id
  expose :user, presenter: SimplePresenter
  expose :comment, presenter: SimplePresenter
end