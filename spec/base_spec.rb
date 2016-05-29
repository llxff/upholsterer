describe Upholsterer::Base do
  describe '.expose' do
    context 'not using :with option' do
      subject { UserPresenter.new }

      it { is_expected.to respond_to(:name) }
      it { is_expected.to respond_to(:email) }
      it { is_expected.not_to respond_to(:password_hash) }
      it { is_expected.not_to respond_to(:password_salt) }
    end

    context 'using :with option' do
      subject { CommentPresenter.new }

      it { is_expected.to respond_to(:user_name) }
    end

    context 'using :as option' do
      let(:site) { double(site: 'http://example.org') }
      subject { AliasPresenter.new(site) }

      it { is_expected.to respond_to(:url) }
      it { expect(subject.url).to eql('http://example.org') }
    end

    context 'exposing iterators' do
      subject { IteratorPresenter.new([1, 2, 3]) }

      its(:each) { is_expected.to be_a(Enumerator) }

      it 'uses provided block' do
        numbers = []
        subject.each {|n| numbers << n}
        expect(numbers).to eql([1, 2, 3])
      end
    end
  end

  describe '.attributes' do
    context 'using defaults' do
      let(:presenter) { UserPresenter }
      subject { presenter.attributes }

      it { is_expected.to have(2).items }
      its([:name]) { is_expected.to eql([:name, {}]) }
      its([:email]) { is_expected.to eql([:email, {}]) }
    end

    context 'using provided options' do
      let(:presenter) { CommentPresenter }
      subject { presenter.attributes }

      it { is_expected.to have(3).items }
      its([:user_name]) { is_expected.to eql([:name, {with: :user}]) }
      its([:post_title]) { is_expected.to eql([:title, {with: :post}]) }
    end
  end

  describe '.subjects' do
    it 'is aliased as .subject' do
      thing = double('Thing')
      presenter_class = Class.new(Presenter)
      presenter_class.subject :thing
      presenter = presenter_class.new(thing)

      expect(presenter.instance_variable_get('@thing')).to eql(thing)
    end

    context 'using defaults' do
      let(:user) { double name: 'John Doe', email: 'john@doe.com' }
      subject { UserPresenter.new(user) }

      its(:name) { is_expected.to eq 'John Doe' }
      its(:email) { is_expected.to eq 'john@doe.com' }

      it 'responds to private subject method' do
        expect(subject.public_methods).to include(:subject)
      end

      it 'returns subject' do
        expect(subject.send(:subject)).to eql(user)
      end
    end

    context 'specifying several subjects' do
      let(:user) { double name: 'John Doe' }
      let(:comment) { double body: 'Some comment', user: user }
      let(:post) { double title: 'Some post' }
      subject { CommentPresenter.new(comment, post) }

      its(:body) { is_expected.to eq 'Some comment' }
      its(:post_title) { is_expected.to eq 'Some post' }
      its(:user_name) { is_expected.to eq 'John Doe' }

      it 'responds to private comment method' do
        expect(subject.private_methods).to include(:comment)
      end

      it 'responds to private post method' do
        expect(subject.private_methods).to include(:post)
      end

      it 'returns comment subject' do
        expect(subject.send(:comment)).to eql(comment)
      end

      it 'returns post subject' do
        expect(subject.send(:post)).to eql(post)
      end
    end

    context 'when subjects are nil' do
      let(:comment) { double body: 'Some comment' }
      subject { CommentPresenter.new(comment, nil) }

      its(:post_title) { is_expected.to be_nil }
    end
  end

  describe '.map' do
    context 'wraps a single subject' do
      let(:user) { double name: 'John Doe' }
      subject { UserPresenter.map([user])[0] }

      it { is_expected.to be_a(UserPresenter) }
      its(:name) { is_expected.to eq 'John Doe' }
    end

    context 'wraps several subjects' do
      let(:comment) { double body: 'Some comment' }
      let(:post) { double title: 'Some post' }
      let(:user) { double name: 'John Doe' }
      subject { CommentPresenter.map([[comment, post]])[0] }

      it { is_expected.to be_a(CommentPresenter) }
      its(:body) { is_expected.to eq 'Some comment' }
      its(:post_title) { is_expected.to eq 'Some post' }
    end
  end

  describe '#initialize' do
    let(:user) { double }
    subject { UserPresenter.new(user) }

    it 'assigns the subject' do
      expect(subject.instance_variable_get('@subject')).to eql(user)
    end
  end

  describe 'inherited presenter' do
    let(:presenter) { Class.new(CommentPresenter) }

    context 'subjects' do
      subject { presenter.subjects }

      specify { expect(subject).to have(2).items }
      specify { expect(subject.first).to eql(:comment) }
      specify { expect(subject.last).to eql(:post) }
    end

    context 'attributes' do
      subject { presenter.attributes }

      it { is_expected.to have(3).items }
      its([:user_name]) { is_expected.to eql([:name, {with: :user}]) }
      its([:post_title]) { is_expected.to eql([:title, {with: :post}]) }
    end

    context 'do_not_use_prefixes' do
      subject { presenter }

      context 'without setting' do
        its(:do_not_use_prefixes?) { is_expected.to be_falsey }
      end

      context 'with setting' do
        before { CommentPresenter.do_not_use_prefixes! }

        its(:do_not_use_prefixes?) { is_expected.to be_truthy }
      end
    end
  end

  describe 'as json' do
    let(:user) { double name: 'John Doe' }
    let(:comment) { double body: 'Some comment', user: user }
    let(:post) { double title: 'Some post' }
    subject { CommentPresenter.new(comment, post).to_hash }

    its(:keys) { is_expected.to match_array [:body, :user_name, :post_title] }
    its([:body]) { is_expected.to eq 'Some comment' }
    its([:user_name]) { is_expected.to eq 'John Doe'}
    its([:post_title]) { is_expected.to eq 'Some post'}
  end

  describe 'serializable' do
    describe 'with inheritance' do
      subject { SerializablePresenter.new(double).to_json }

      it { is_expected.to eq '{"one":1,"two":2}'}
    end
  end

  describe 'expose with block' do
    let(:project) { double id: 1, description: 'description', type: 'type' }
    subject { CollectPresenter.new(entity) }

    context 'Test presenter' do
      let(:entity) { double name: 'Test', project: project, email: 'foo@bar.com' }

      its(:id) { is_expected.to eq 1 }
      its(:name) { is_expected.to eq 'Test' }
      its(:email) { is_expected.to eq 'foo@bar.com' }
      its(:type) { is_expected.to eq 'test_type' }
      its(:description) { is_expected.to eq 'test_description' }
      its(:to_json) { is_expected.to be_json_with(name: 'Test', email: 'foo@bar.com', id: 1, description: 'test_description', type: 'test_type') }
    end

    context 'Real presenter' do
      let(:entity) { double name: 'Real', project: project, email: 'foo@bar.com' }

      its(:name) { is_expected.to eq 'Real' }
      its(:email) { is_expected.to eq 'foo@bar.com' }
      its(:type) { is_expected.to eq 'real_type' }
      its(:description) { is_expected.to eq 'real_description' }
      its(:to_json) { is_expected.to be_json_with(name: 'Real', email: 'foo@bar.com', id: 1, description: 'real_description', type: 'real_type') }
    end
  end

  describe 'expose with other presenter' do
    context 'with several subjects' do
      let(:user) { double name: 'Peter', email: 'peter@email.com' }
      let(:comment) { double(user: double(name: 'Steve', email: 'steve@email.com')) }

      subject { ExposeWithOtherPresenter.new(user, comment) }

      its(:name) { is_expected.to eq 'Peter' }

      specify { expect(subject.creator.name).to eq 'Steve' }
      specify { expect(subject.creator.email).to eq 'steve@email.com' }
      its(:to_json) { is_expected.to be_json_with(name: 'Peter', creator: { name: 'Steve', email: 'steve@email.com'}) }
    end

    context 'with one subject' do
      let(:user) { double name: 'Peter', email: 'peter@email.com' }
      let(:post) { double user: user, comment: nil, id: 1}

      subject { ExposeWithOneSubjectPresenter.new(post) }

      its(:id) { is_expected.to eq 1 }
      its(:comment) { is_expected.to be_nil }

      specify { expect(subject.user.name).to eq 'Peter' }
      specify { expect(subject.user.email).to eq 'peter@email.com' }

      its(:to_json) { is_expected.to be_json_with(id: 1, user: { name: 'Peter', email: 'peter@email.com'}, comment: nil) }
    end

    context 'when presenter is anonym class' do
      let(:anonym_presenter) do
        Class.new(Presenter).tap do |presenter|
          presenter.expose :name
          presenter.expose :email
        end
      end

      let(:presenter) do
        Class.new(Presenter).tap do |presenter|
          presenter.expose :id
          presenter.expose :user, presenter: anonym_presenter
          presenter.expose :comment, presenter: anonym_presenter
        end
      end

      let(:user) { double name: 'Peter', email: 'peter@email.com' }
      let(:post) { double user: user, comment: nil, id: 1}

      subject { presenter.new(post) }

      its(:id) { is_expected.to eq 1 }
      its(:comment) { is_expected.to be_nil }

      specify { expect(subject.user.name).to eq 'Peter' }
      specify { expect(subject.user.email).to eq 'peter@email.com' }

      its(:to_json) { is_expected.to be_json_with(id: 1, user: { name: 'Peter', email: 'peter@email.com'}, comment: nil) }
      its(:as_json) { is_expected.to eq('id' => 1, 'user' => { 'name' => 'Peter', 'email' => 'peter@email.com'}, 'comment' => nil) }
    end
  end

  describe 'custom subject' do
    let(:presenter) do
      Class.new(Presenter) do
        subjects :message, :user

        expose :id
        expose :name, with: :user

        private

        def user
          message.recipient.user
        end
      end
    end

    subject { presenter.new(double(id: 1, recipient: double(user: double(name: 'Tom')))) }

    its(:id) { is_expected.to eq 1 }
    its(:user_name) { is_expected.to eq 'Tom' }
  end
end
