class SerializableParentPresenter < Presenter
  serializable :one, :two

  def one
    1
  end

  def two
    2
  end

  def three
    3
  end
end


class SerializablePresenter < SerializableParentPresenter
end