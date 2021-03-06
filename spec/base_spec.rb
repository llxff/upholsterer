describe Upholsterer::Base do
  describe '.expose' do
    context 'not using :with option' do
      subject { UserPresenter.new }

      it { should respond_to(:name) }
      it { should respond_to(:email) }
      it { should_not respond_to(:password_hash) }
      it { should_not respond_to(:password_salt) }
    end

    context 'using :with option' do
      subject { CommentPresenter.new }

      it { should respond_to(:user_name) }
    end

    context 'using :as option' do
      let(:site) { OpenStruct.new(site: 'http://example.org') }
      subject { AliasPresenter.new(site) }

      it { should respond_to(:url) }
      it { expect(subject.url).to eql('http://example.org') }
    end

    context 'exposing iterators' do
      subject { IteratorPresenter.new([1, 2, 3]) }

      its(:each) { should be_a(Enumerator) }

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

      it { should have(2).items }
      its([:name]) { should eql([:name, {}]) }
      its([:email]) { should eql([:email, {}]) }
    end

    context 'using provided options' do
      let(:presenter) { CommentPresenter }
      subject { presenter.attributes }

      it { should have(3).items }
      its([:user_name]) { should eql([:name, {with: :user}]) }
      its([:post_title]) { should eql([:title, {with: :post}]) }
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

      its(:name) { should == 'John Doe' }
      its(:email) { should == 'john@doe.com' }

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

      its(:body) { should == 'Some comment' }
      its(:post_title) { should == 'Some post' }
      its(:user_name) { should == 'John Doe' }

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

      its(:post_title) { should be_nil }
    end
  end

  describe '.map' do
    context 'wraps a single subject' do
      let(:user) { double name: 'John Doe' }
      subject { UserPresenter.map([user])[0] }

      it { should be_a(UserPresenter) }
      its(:name) { should == 'John Doe' }
    end

    context 'wraps several subjects' do
      let(:comment) { double body: 'Some comment' }
      let(:post) { double title: 'Some post' }
      let(:user) { double name: 'John Doe' }
      subject { CommentPresenter.map([[comment, post]])[0] }

      it { should be_a(CommentPresenter) }
      its(:body) { should == 'Some comment' }
      its(:post_title) { should == 'Some post' }
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

      it { should have(3).items }
      its([:user_name]) { should eql([:name, {with: :user}]) }
      its([:post_title]) { should eql([:title, {with: :post}]) }
    end

    context 'do_not_use_prefixes' do
      subject { presenter }

      context 'without setting' do
        its(:do_not_use_prefixes?) { should be_false }
      end

      context 'with setting' do
        before { CommentPresenter.do_not_use_prefixes! }

        its(:do_not_use_prefixes?) { should be_true }
      end
    end
  end

  describe 'as json' do
    let(:user) { double name: 'John Doe' }
    let(:comment) { double body: 'Some comment', user: user }
    let(:post) { double title: 'Some post' }
    subject { CommentPresenter.new(comment, post).to_hash }

    its(:keys) { should match_array [:body, :user_name, :post_title] }
    its([:body]) { should eq 'Some comment' }
    its([:user_name]) { should eq 'John Doe'}
    its([:post_title]) { should eq 'Some post'}
  end

  describe 'as json with expose all' do
    let(:comment) { double body: 'Some comment', user: 'user' }
    subject { ExposeAllPresenter.new(comment).to_json }

    it { should eq '{}' }
  end

  describe 'serializable' do
    describe 'with inheritance' do
      subject { SerializablePresenter.new(double).to_json }

      it { should eq '{"one":1,"two":2}'}
    end
  end

  describe 'expose with block' do
    let(:project) { double id: 1, description: 'description', type: 'type' }
    subject { CollectPresenter.new(entity) }

    context 'Test presenter' do
      let(:entity) { double name: 'Test', project: project, email: 'foo@bar.com' }

      its(:id) { should eq 1 }
      its(:name) { should eq 'Test' }
      its(:email) { should eq 'foo@bar.com' }
      its(:type) { should eq 'test_type' }
      its(:description) { should eq 'test_description' }
      its(:to_json) { should be_json_with(name: 'Test', email: 'foo@bar.com', id: 1, description: 'test_description', type: 'test_type') }
    end

    context 'Real presenter' do
      let(:entity) { double name: 'Real', project: project, email: 'foo@bar.com' }

      its(:name) { should eq 'Real' }
      its(:email) { should eq 'foo@bar.com' }
      its(:type) { should eq 'real_type' }
      its(:description) { should eq 'real_description' }
      its(:to_json) { should be_json_with(name: 'Real', email: 'foo@bar.com', id: 1, description: 'real_description', type: 'real_type') }
    end
  end

  describe 'expose with other presenter' do
    context 'with several subjects' do
      let(:user) { double name: 'Peter', email: 'peter@email.com' }
      let(:comment) { double(user: double(name: 'Steve', email: 'steve@email.com')) }

      subject { ExposeWithOtherPresenter.new(user, comment) }

      its(:name) { should eq 'Peter' }

      specify { expect(subject.creator.name).to eq 'Steve' }
      specify { expect(subject.creator.email).to eq 'steve@email.com' }
      its(:to_json) { should be_json_with(name: 'Peter', creator: { name: 'Steve', email: 'steve@email.com'}) }
    end

    context 'with one subject' do
      let(:user) { double name: 'Peter', email: 'peter@email.com' }
      let(:post) { double user: user, comment: nil, id: 1}

      subject { ExposeWithOneSubjectPresenter.new(post) }

      its(:id) { should eq 1 }
      its(:comment) { should be_nil }

      specify { expect(subject.user.name).to eq 'Peter' }
      specify { expect(subject.user.email).to eq 'peter@email.com' }

      its(:to_json) { should be_json_with(id: 1, user: { name: 'Peter', email: 'peter@email.com'}, comment: nil) }
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

      its(:id) { should eq 1 }
      its(:comment) { should be_nil }

      specify { expect(subject.user.name).to eq 'Peter' }
      specify { expect(subject.user.email).to eq 'peter@email.com' }

      its(:to_json) { should be_json_with(id: 1, user: { name: 'Peter', email: 'peter@email.com'}, comment: nil) }
      its(:as_json) { should eq('id' => 1, 'user' => { 'name' => 'Peter', 'email' => 'peter@email.com'}, 'comment' => nil) }
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

    its(:id) { should eq 1 }
    its(:user_name) { should eq 'Tom' }
  end
end
