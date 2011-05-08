require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe 'Locksmith' do
  before(:each) do
    @private_password = 'private_password'
    @domain = 'domain'
    @username = 'username'
    @options = {
        :use_alphabet => true,
        :use_number => true,
        :use_symbol => true
    }
    @locksmith = Locksmith.new(@private_password, @domain, @username, @options)
  end

  it 'should save the attributes' do
    @locksmith.private_password.should == @private_password
    @locksmith.domain.should == @domain
    @locksmith.username.should == @username
    @locksmith.use_alphabet?.should == true
    @locksmith.use_number?.should == true
    @locksmith.use_symbol?.should == true
  end

  it 'should be able to change the attributes' do
    [:private_password, :domain, :username].each do |attribute|
      @locksmith.send(attribute).should == instance_variable_get('@' + attribute.to_s)

      setter_name = attribute.to_s + '='
      new_value = 'new ' + attribute.to_s
      @locksmith.send(setter_name.to_sym, new_value)
      @locksmith.send(attribute).should == new_value
    end
    [:use_alphabet, :use_number, :use_symbol].each do |attribute|
      getter_name = attribute.to_s + '?'
      @locksmith.send(getter_name.to_sym).should == @options[attribute]

      setter_name = attribute.to_s + '='
      new_value = 'new ' + attribute.to_s
      @locksmith.send(setter_name.to_sym, new_value)
      @locksmith.send(getter_name.to_sym).should == new_value
    end
  end

  it 'should be able create an instance with defaults' do
    locksmith = Locksmith.new('my password', 'my domain')
    locksmith.private_password.should == 'my password'
    locksmith.domain.should == 'my domain'
    locksmith.username.should == ''
    locksmith.use_alphabet?.should == true
    locksmith.use_number?.should == true
    locksmith.use_symbol?.should == true
  end

  describe 'validation' do
    it 'should be able to validate' do
      @locksmith.valid?.should == true
      @locksmith.errors.should == []
    end

    it 'should check the existance of private_password' do
      @locksmith.private_password = ''
      @locksmith.valid?.should == false
      @locksmith.errors.should == ['private password is required']
    end

    it 'should check the existance of domain' do
      @locksmith.domain = ''
      @locksmith.valid?.should == false
      @locksmith.errors.should == ['domain is required']
    end

    it 'at least one of use_alphabet or use_number or use_symbol must be true' do
      @locksmith.use_alphabet = false
      @locksmith.use_number = false
      @locksmith.use_symbol = false
      @locksmith.valid?.should == false
      @locksmith.errors.should == ['at least on of use_alphabet, use_number or use_symbol must be true']
    end
  end

  describe 'password generation' do
    it 'should raise exception if it is not valid' do
      @locksmith.domain = nil
      lambda { @locksmith.generated_password }.should raise_error('Can not generate password: domain is required')
    end

    it 'should generate password if it is valid' do
      @locksmith.generated_password.should_not be_nil
      @locksmith.generated_password.should_not == ''
    end

    it 'should generate the same password if the attributes are the same' do
      previous_password = @locksmith.generated_password
      @locksmith.generated_password.should == previous_password
    end

    it 'should generate the different password if the attributes are not the same' do
      previous_password = @locksmith.generated_password
      @locksmith.domain = 'domain1'
      @locksmith.generated_password.should_not == previous_password

      previous_password = @locksmith.generated_password
      @locksmith.private_password = 'private_password1'
      @locksmith.generated_password.should_not == previous_password

      previous_password = @locksmith.generated_password
      @locksmith.username = 'username1'
      @locksmith.generated_password.should_not == previous_password
    end

    it 'should start with upper case alphabet followed by lower case alphabet' do
      @locksmith.generated_password.should match /^[A-Z][a-z]/
    end

    it 'should have alphabet, number, symbol in the first six characters' do
      beginning = @locksmith.generated_password[0, 6]
      beginning.should match /[a-z]/
      beginning.should match /[A-Z]/
      beginning.should match /\d/
      beginning.should match /[~!@#\$%^&*()_+-={}|\[\]\\;':"<>?,.\/]/
    end

    it 'should generate alphabetic only password if requested' do
      @locksmith.use_alphabet = true
      @locksmith.use_number = false
      @locksmith.use_symbol = false
      @locksmith.generated_password.should match /^[A-Z][a-z][a-zA-Z]+$/
    end

    it 'should generate numeric only password if requested' do
      @locksmith.use_alphabet = false
      @locksmith.use_number = true
      @locksmith.use_symbol = false
      @locksmith.generated_password.should match /^\d+$/
    end

    it 'should generate symbolic only password if requested' do
      @locksmith.use_alphabet = false
      @locksmith.use_number = false
      @locksmith.use_symbol = true
      @locksmith.generated_password.should match /^[~!@#\$%^&*()_+-={}|\[\]\\;':"<>?,.\/]+$/
    end

    it 'should be able to limit the generated password length' do
      generated_password = @locksmith.generated_password

      @locksmith.max_length = 6
      @locksmith.generated_password.should == generated_password[0,6]

      @locksmith.max_length = 1000
      @locksmith.generated_password.should == generated_password

      @locksmith.max_length = 0
      @locksmith.generated_password.should == ''

      @locksmith.max_length = nil
      @locksmith.generated_password.should == generated_password
    end
  end
end
