const String PAYMENT_REQUEST = r'''
mutation storeOrderPaymentRequest(
    $siteId: Int!
    $gatewayId: Int!
    $amount: Float!
    $callBack: String
    $cancelUrl: String!
    $currency: String!
    $customerAddress: String
    $customerName: String!
    $customerPhone: String
    $emiDuration: Int!
    $emiInterest: Float!
    $failUrl: String!
    $isCardTransaction: Boolean!
    $isCodPayment: Boolean!
    $isEmi: Boolean!
    $merchantId: Int!
    $message: String
    $optionA: String
    $optionB: String
    $optionC: String
    $optionD: String
    $optionE: String
    $otherUrl: String
    $payeeSource: String!
    $paymentId: String
    $productInfo: String!
    $referenceId: String!
    $shipAddress: String
    $showRefundButton: Boolean!
    $successUrl: String!
    $transactionSource: String
    $transactionType: Int!
  ) {
    storeOrderPaymentRequest(
      siteId: $siteId
      gatewayId: $gatewayId
      data: {
        amount: $amount
        callBack: $callBack
        cancelUrl: $cancelUrl
        currency: $currency
        customerAddress: $customerAddress
        customerName: $customerName
        customerPhone: $customerPhone
        emiDuration: $emiDuration
        emiInterest: $emiInterest
        failUrl: $failUrl
        isCardTransaction: $isCardTransaction
        isCodPayment: $isCodPayment
        isEmi: $isEmi
        merchantId: $merchantId
        message: $message
        optionA: $optionA
        optionB: $optionB
        optionC: $optionC
        optionD: $optionD
        optionE: $optionE
        otherUrl: $otherUrl
        payeeSource: $payeeSource
        paymentId: $paymentId
        productInfo: $productInfo
        referenceId: $referenceId
        shipAddress: $shipAddress
        showRefundButton: $showRefundButton
        successUrl: $successUrl
        transactionSource: $transactionSource
        transactionType: $transactionType
      }
    ) {
      amount
      callBack
      cancelUrl
      currency
      customerName
      displayValue
      failUrl
      id
      isCaptured
      isPaid
      merchantId
      productInfo
      referenceId
      showRefundButton
      status
      successUrl
      transactionType
      transactionId
    }
  }
 ''';
