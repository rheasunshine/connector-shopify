class Entities::Financial < Maestrano::Connector::Rails::ComplexEntity
  def self.connec_entities_names
    %w(Invoice Payment)
  end

  def self.external_entities_names
    %w(Order Transaction)
  end

  def self.public_external_entity_name
    'Orders'
  end

  def before_sync(last_synchronization_date)
    # TODO manage when country differs from currency 'countries or money gem'
    current_country_code = @external_client.find('Shop')&.first.dig('country_code')
    countries = @external_client.find 'Country'
    @opts[:country_tax_rate] ||= countries.find {|country| country['code'] == current_country_code}&.dig('tax')
  end

#   # input :  {
#   #             connec_entity_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2],
#   #             connec_entity_names[1]: [unmapped_connec_entitiy3, unmapped_connec_entitiy4]
#   #          }
#   # output : {
#   #             connec_entity_names[0]: {
#   #               external_entities_names[0]: [unmapped_connec_entitiy1, unmapped_connec_entitiy2]
#   #             },
#   #             connec_entity_names[1]: {
#   #               external_entities_names[0]: [unmapped_connec_entitiy3],
#   #               external_entities_names[1]: [unmapped_connec_entitiy4]
#   #             }
#   #          }

# All the entitites are read only, no need to send them
  def connec_model_to_external_model(connec_hash_of_entities)
    {}
  end

#   # input :  {
#   #             external_entities_names[0]: [unmapped_external_entity1, unmapped_external_entity2],
#   #             external_entities_names[1]: [unmapped_external_entity3, unmapped_external_entity4]
#   #          }
#   # output : {
#   #             external_entities_names[0]: {
#   #               connec_entity_names[0]: [unmapped_external_entity1],
#   #               connec_entity_names[1]: [unmapped_external_entity2]
#   #             },
#   #             external_entities_names[1]: {
#   #               connec_entity_names[0]: [unmapped_external_entity3, unmapped_external_entity4]
#   #             }
#   #           }
  TRANSACTION_KINDS = %w(sale refund)
  def external_model_to_connec_model(external_hash_of_entities)
    orders = external_hash_of_entities['Order']

    transactions = orders.map { |order| order['transactions'] }
                       .compact.flatten
                       .select { |t| t['status'] == 'success' && TRANSACTION_KINDS.include?(t['kind']) }
    {
        'Order' => {'Invoice' => orders},
        'Transaction' => {'Payment' => transactions}
    }
  end
end
