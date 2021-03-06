class Order < ActiveRecord::Base

  include AASM

  aasm_column :state
  aasm_initial_state :new
  aasm_state :new
  aasm_state :waiting
  aasm_state :payment_done
  aasm_state :timeouted
  aasm_state :canceled

  aasm_event :submit do
    transitions :to => :waiting, :from => [:new]
  end

  aasm_event :cancel do
    transitions :to => :canceled, :from => [:waiting]
  end

  aasm_event :timeout do
    transitions :to => :timeouted, :from => [:waiting]
  end

  aasm_event :pay do
    transitions :to => :payment_done, :from => [:waiting]
  end

  def save_on_gopay
    payment = GoPay::EshopPayment.new({:variable_symbol => "gopay_test_#{GoPay.configuration.goid}",
                                       :total_price_in_cents => price.to_i,
                                       :product_name => name,
                                       :payment_channels => payment_method_code.present? ? [payment_method_code] : GoPay::PaymentMethod.all.map(&:code)}).create
    self.payment_session_id = payment.payment_session_id
    save!
  end

  def payment
    GoPay::EshopPayment.new(:variable_symbol => "gopay_test_#{GoPay.configuration.goid}",
                            :total_price_in_cents => price.to_i,
                            :product_name => name,
                            :payment_session_id => payment_session_id,
                            :payment_channels => []).actual
  end

  def payment_attrs
    response = payment.last_response
    ppayment_chanel = response[:payment_channel].is_a?(Hash) ? "" : payment.last_response[:payment_channel]
    {:payment_channel => ppayment_chanel,
     :session_state => response[:session_state]}
  end

  def gopay_url
    GoPay::Payment.new(:payment_session_id => payment_session_id).gopay_url
  end

end
