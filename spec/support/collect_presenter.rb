class CollectPresenter < Presenter
  expose :name, :email
  expose :id, with: :project, prefix: false
  expose :description, :type, with: :project, prefix: false do
    "#{ name }ProjectPresenter".constantize
  end
end

class TestProjectPresenter
  def initialize(project)
    @project = project
  end

  def description
    "test_#{ @project.description}"
  end

  def type
    "test_#{ @project.type }"
  end
end

class RealProjectPresenter
  def initialize(project)
    @project = project
  end

  def description
    "real_#{ @project.description}"
  end

  def type
    "real_#{ @project.type }"
  end
end