require 'test_helper'

class OpenAPITest < Minitest::Test
  CAT_SCHEMA = {
    'type' => 'object',
    'properties' => {
      'name' => {
        'type' => 'string'
      }
    }
  }
  DOG_SCHEMA = {
    'properties' => {
      'bark' => {
        'type' => 'string'
      }
    }
  }
  LIZARD_SCHEMA = {
    'properties' => {
      'lovesRocks' => {
        'type' => 'boolean'
      }
    }
  }
  MONSTER_SCHEMA = {
    'properties' => {
      'hungry' => {
        'type' => 'boolean'
      }
    }
  }

  CAT = {
    'id' => 12345,
    'petType' => 'Cat'
  }
  MISTY = {
    'petType' => 'Cat',
    'name' => 'misty'
  }
  INVALID_CAT = {
    'petType' => 'Cat',
    'name' => 1
  }
  DOG = {
    'petType' => 'Dog',
    'bark' => 'soft'
  }
  INVALID_DOG = {
    'petType' => 'Dog',
    'bark' => 1
  }
  LIZARD = {
    'petType' => 'Lizard',
    'lovesRocks' => true
  }
  INVALID_LIZARD = {
    'petType' => 'Lizard',
    'lovesRocks' => 'yes'
  }
  MONSTER = {
    'petType' => 'monster',
    'hungry' => true
  }
  INVALID_MONSTER = {
    'petType' => 'monster',
    'hungry' => 'kinda'
  }

  def test_discriminator_specification_example
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'Pet' => {
            'type' => 'object',
            'discriminator' => {
              'propertyName' => 'petType'
            },
            'properties' => {
              'name' => {
                'type' => 'string'
              },
              'petType' => {
                'type' => 'string'
              }
            },
            'required' => [
              'name',
              'petType'
            ]
          },
          'Cat' => {
            'description' => 'A representation of a cat. Note that `Cat` will be used as the discriminator value.',
            'allOf' => [
              {
                '$ref' => '#/components/schemas/Pet'
              },
              {
                'type' => 'object',
                'properties' => {
                  'huntingSkill' => {
                    'type' => 'string',
                    'description' => 'The measured skill for hunting',
                    'default' => 'lazy',
                    'enum' => [
                      'clueless',
                      'lazy',
                      'adventurous',
                      'aggressive'
                    ]
                  }
                },
                'required' => [
                  'huntingSkill'
                ]
              }
            ]
          },
          'Dog' => {
            'description' => 'A representation of a dog. Note that `Dog` will be used as the discriminator value.',
            'allOf' => [
              {
                '$ref' => '#/components/schemas/Pet'
              },
              {
                'type' => 'object',
                'properties' => {
                  'packSize' => {
                    'type' => 'integer',
                    'format' => 'int32',
                    'description' => 'the size of the pack the dog is from',
                    'default' => 0,
                    'minimum' => 0
                  }
                },
                'required' => [
                  'packSize'
                ]
              }
            ]
          }
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('Pet')

    george = {
      'petType' => 'Cat',
      'name' => 'George',
      'huntingSkill' => 'aggressive'
    }
    pj = {
      'petType' => 'Cat',
      'name' => 'PJ',
      'huntingSkill' => 'clueless'
    }
    edie = {
      'petType' => 'Dog',
      'name' => 'Edie',
      'packSize' => 2
    }
    ray = {
      'petType' => 'Dog',
      'name' => 'Ray',
      'packSize' => 2
    }
    missing_hunting_skill = {
      'petType' => 'Cat',
      'name' => 'Peace'
    }
    invalid_hunting_skill = {
      'petType' => 'Cat',
      'name' => 'Maverick',
      'huntingSkill' => 'untamed'
    }
    missing_pack_size = {
      'petType' => 'Dog',
      'name' => 'Loner'
    }
    invalid_pack_size = {
      'petType' => 'Dog',
      'name' => 'Heaven',
      'packSize' => 2.pow(32)
    }
    missing_pet_type = {
      'name' => 'Brian'
    }
    missing_name = {
      'petType' => 'Cat'
    }
    invalid_pet_type = {
      'petType' => 'Rock',
      'name' => 'Crystal'
    }

    assert(schemer.valid_schema?)
    assert(schemer.valid?(george))
    assert(schemer.valid?(pj))
    assert(schemer.valid?(edie))
    assert(schemer.valid?(ray))
    assert_equal([['required', '/components/schemas/Cat/allOf/1']], schemer.validate(missing_hunting_skill).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['enum', '/components/schemas/Cat/allOf/1/properties/huntingSkill']], schemer.validate(invalid_hunting_skill).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['required', '/components/schemas/Dog/allOf/1']], schemer.validate(missing_pack_size).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['format', '/components/schemas/Dog/allOf/1/properties/packSize']], schemer.validate(invalid_pack_size).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['required', '/components/schemas/Pet'], ['discriminator', '/components/schemas/Pet']], schemer.validate(missing_pet_type).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['required', '/components/schemas/Pet'], ['required', '/components/schemas/Cat/allOf/1']], schemer.validate(missing_name).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['discriminator', '/components/schemas/Pet']], schemer.validate(invalid_pet_type).map { |error| error.values_at('type', 'schema_pointer') })
  end

  def test_all_of_discriminator
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'Pet' => {
            'type' => 'object',
            'required' => ['petType'],
            'properties' => {
              'petType' => {
                'type' => 'string'
              }
            },
            'discriminator' => {
              'propertyName' => 'petType',
              'mapping' => {
                'dog' => 'Dog'
              }
            }
          },
          'Cat' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              CAT_SCHEMA
            ]
          },
          'Dog' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              DOG_SCHEMA
            ]
          },
          'Lizard' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              LIZARD_SCHEMA
            ]
          }
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('Pet')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/allOf/1/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(DOG))
    assert_equal(['/components/schemas/Dog/allOf/1/properties/bark'], schemer.validate(INVALID_DOG).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(LIZARD))
    assert_equal(['/components/schemas/Lizard/allOf/1/properties/lovesRocks'], schemer.validate(INVALID_LIZARD).map { |error| error.fetch('schema_pointer') })
  end

  def test_any_of_discriminator
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'anyOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Dog' },
              { '$ref' => '#/components/schemas/Lizard' }
            ],
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => CAT_SCHEMA,
          'Dog' => DOG_SCHEMA,
          'Lizard' => LIZARD_SCHEMA
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(DOG))
    assert_equal(['/components/schemas/Dog/properties/bark'], schemer.validate(INVALID_DOG).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(LIZARD))
    assert_equal(['/components/schemas/Lizard/properties/lovesRocks'], schemer.validate(INVALID_LIZARD).map { |error| error.fetch('schema_pointer') })
  end

  def test_one_of_discriminator
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'oneOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Dog' },
              { '$ref' => '#/components/schemas/Lizard' }
            ],
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => CAT_SCHEMA,
          'Dog' => DOG_SCHEMA,
          'Lizard' => LIZARD_SCHEMA
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(DOG))
    assert_equal(['/components/schemas/Dog/properties/bark'], schemer.validate(INVALID_DOG).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(LIZARD))
    assert_equal(['/components/schemas/Lizard/properties/lovesRocks'], schemer.validate(INVALID_LIZARD).map { |error| error.fetch('schema_pointer') })
  end

  def test_all_any_one_without_discriminator
    assert(JSONSchemer.schema({ 'allOf' => [true, true, true] }, :meta_schema => JSONSchemer.openapi31).valid?({}))
    refute(JSONSchemer.schema({ 'allOf' => [true, true, false] }, :meta_schema => JSONSchemer.openapi31).valid?({}))
    assert(JSONSchemer.schema({ 'anyOf' => [true, true, false] }, :meta_schema => JSONSchemer.openapi31).valid?({}))
    refute(JSONSchemer.schema({ 'anyOf' => [false, false, false] }, :meta_schema => JSONSchemer.openapi31).valid?({}))
    assert(JSONSchemer.schema({ 'oneOf' => [true, false, false] }, :meta_schema => JSONSchemer.openapi31).valid?({}))
    refute(JSONSchemer.schema({ 'oneOf' => [true, true, false] }, :meta_schema => JSONSchemer.openapi31).valid?({}))
  end

  def test_all_of_discriminator_without_all_of
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'Pet' => {
            'type' => 'object',
            'required' => ['petType'],
            'properties' => {
              'petType' => {
                'type' => 'string'
              }
            },
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => CAT_SCHEMA
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('Pet')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
  end

  def test_all_of_discriminator_subclass_schemas_work_on_their_own
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'Pet' => {
            'type' => 'object',
            'required' => ['petType'],
            'properties' => {
              'petType' => {
                'type' => 'string'
              }
            },
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              CAT_SCHEMA
            ]
          }
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('Cat')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/allOf/1/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    assert_equal([['required', '/components/schemas/Pet'], ['discriminator', '/components/schemas/Pet']], schemer.validate({}).map { |error| error.values_at('type', 'schema_pointer') })
  end

  def test_all_of_discriminator_with_non_discriminator_ref
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'Pet' => {
            'type' => 'object',
            'required' => ['petType'],
            'properties' => {
              'petType' => {
                'type' => 'string'
              }
            },
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => {
            'allOf' => [
              { '$ref' => '#/components/schemas/Pet' },
              { '$ref' => '#/components/schemas/Other' },
              CAT_SCHEMA
            ]
          },
          'Other' => {
            'required' => ['other'],
          }
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('Cat')

    assert(schemer.valid_schema?)
    refute(schemer.valid?(CAT))
    assert(schemer.valid?(CAT.merge('other' => 'y')))
    assert_equal(['/components/schemas/Other', '/components/schemas/Cat/allOf/2/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    assert_equal([['required', '/components/schemas/Pet'], ['discriminator', '/components/schemas/Pet'], ['required', '/components/schemas/Other']], schemer.validate({}).map { |error| error.values_at('type', 'schema_pointer') })
  end

  def test_all_of_discriminator_with_remote_ref
    schema = {
      '$id' => 'http://example.com/schema',
      'discriminator' => {
        'propertyName' => 'petType',
        'mapping' => {
          'Dog' => 'http://example.com/dog'
        }
      }
    }
    schemer = JSONSchemer.schema(
      schema,
      :meta_schema => JSONSchemer.openapi31,
      :ref_resolver => {
        URI('http://example.com/schema') => schema,
        URI('http://example.com/cat') => {
          'allOf' => [
            { '$ref' => 'http://example.com/schema' },
            CAT_SCHEMA
          ]
        },
        URI('http://example.com/dog') => {
          'allOf' => [
            { '$ref' => 'http://example.com/schema' },
            DOG_SCHEMA
          ]
        }
      }.to_proc
    )

    assert(schemer.valid_schema?)
    refute(schemer.valid?(CAT))
    assert(schemer.valid?(CAT.merge('petType' => 'http://example.com/cat')))
    assert(schemer.valid?(DOG))

    invalid_cat = INVALID_CAT.merge('petType' => 'http://example.com/cat')
    invalid_cat_result = schemer.validate(invalid_cat, output_format: 'basic', resolve_enumerators: true)
    assert_equal('/discriminator/allOf/1/properties/name/type', invalid_cat_result.dig('errors', 0, 'keywordLocation'))
    assert_equal('http://example.com/cat#/allOf/1/properties/name/type', invalid_cat_result.dig('errors', 0, 'absoluteKeywordLocation'))

    invalid_dog_result = schemer.validate(INVALID_DOG, output_format: 'basic', resolve_enumerators: true)
    assert_equal('/discriminator/allOf/1/properties/bark/type', invalid_dog_result.dig('errors', 0, 'keywordLocation'))
    assert_equal('http://example.com/dog#/allOf/1/properties/bark/type', invalid_dog_result.dig('errors', 0, 'absoluteKeywordLocation'))
  end

  def test_any_of_discriminator_without_matching_schema
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'anyOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Dog' }
            ],
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => CAT_SCHEMA,
          'Dog' => DOG_SCHEMA,
          'Lizard' => LIZARD_SCHEMA
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(DOG))
    assert_equal(['/components/schemas/Dog/properties/bark'], schemer.validate(INVALID_DOG).map { |error| error.fetch('schema_pointer') })
    assert_equal([['discriminator', '/components/schemas/MyResponseType']], schemer.validate(LIZARD).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['discriminator', '/components/schemas/MyResponseType']], schemer.validate(INVALID_LIZARD).map { |error| error.values_at('type', 'schema_pointer') })
  end

  def test_one_of_discriminator_without_matching_schema
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'oneOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Dog' }
            ],
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => CAT_SCHEMA,
          'Dog' => DOG_SCHEMA,
          'Lizard' => LIZARD_SCHEMA
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(DOG))
    assert_equal(['/components/schemas/Dog/properties/bark'], schemer.validate(INVALID_DOG).map { |error| error.fetch('schema_pointer') })
    assert_equal([['discriminator', '/components/schemas/MyResponseType']], schemer.validate(LIZARD).map { |error| error.values_at('type', 'schema_pointer') })
    assert_equal([['discriminator', '/components/schemas/MyResponseType']], schemer.validate(INVALID_LIZARD).map { |error| error.values_at('type', 'schema_pointer') })
  end

  def test_any_of_discriminator_ignores_nested_schemas
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'anyOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Cat/$defs/nah' }
            ],
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => CAT_SCHEMA.merge('$defs' => { 'nah' => {} })
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    refute(schemer.valid?(CAT.merge('petType' => 'nah')))
    refute(schemer.valid?(CAT.merge('petType' => 'Cat/$defs/nah')))
  end

  def test_one_of_discriminator_ignores_nested_schemas
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'oneOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Cat/$defs/nah' }
            ],
            'discriminator' => {
              'propertyName' => 'petType'
            }
          },
          'Cat' => CAT_SCHEMA.merge('$defs' => { 'nah' => {} })
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    refute(schemer.valid?(CAT.merge('petType' => 'nah')))
    refute(schemer.valid?(CAT.merge('petType' => 'Cat/$defs/nah')))
  end

  def test_discrimator_mapping
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'oneOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Dog' }
            ],
            'discriminator' => {
              'propertyName' => 'petType',
              'mapping' => {
                'c' => '#/components/schemas/Cat',
                'd' => 'Dog',
                'dog' => 'Dog'
              }
            },
          },
          'Cat' => CAT_SCHEMA,
          'Dog' => DOG_SCHEMA
        }
      }
    }

    schemer = JSONSchemer.openapi(openapi).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT.merge('petType' => 'c')))
    refute(schemer.valid?(MISTY.merge('petType' => 'Cat')))
    assert_equal(['/components/schemas/Cat/properties/name'], schemer.validate(INVALID_CAT.merge('petType' => 'c')).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(DOG.merge('petType' => 'd')))
    assert_equal(['/components/schemas/Dog/properties/bark'], schemer.validate(INVALID_DOG.merge('petType' => 'dog')).map { |error| error.fetch('schema_pointer') })
  end

  def test_non_json_pointer_discriminator
    openapi = {
      'openapi' => '3.1.0',
      'components' => {
        'schemas' => {
          'MyResponseType' => {
            'oneOf' => [
              { '$ref' => '#/components/schemas/Cat' },
              { '$ref' => '#/components/schemas/Dog' },
              { '$ref' => '#/components/schemas/Lizard' },
              { '$ref' => 'https://gigantic-server.com/schemas/Monster/schema.json' }
            ],
            'discriminator' => {
              'propertyName' => 'petType',
              'mapping' => {
                'dog' => '#/components/schemas/Dog',
                'monster' => 'https://gigantic-server.com/schemas/Monster/schema.json'
              }
            }
          },
          'Cat' => CAT_SCHEMA,
          'Dog' => DOG_SCHEMA,
          'Lizard' => LIZARD_SCHEMA
        }
      }
    }

    refs = {
      URI('https://gigantic-server.com/schemas/Monster/schema.json') => MONSTER_SCHEMA
    }

    schemer = JSONSchemer.openapi(openapi, :ref_resolver => refs.to_proc).schema('MyResponseType')

    assert(schemer.valid_schema?)
    assert(schemer.valid?(CAT))
    assert(schemer.valid?(MISTY))
    assert_equal(['/components/schemas/Cat/properties/name'], schemer.validate(INVALID_CAT).map { |error| error.fetch('schema_pointer') })
    refute(schemer.valid?(DOG))
    assert_equal(['/components/schemas/MyResponseType'], schemer.validate(INVALID_DOG).map { |error| error.fetch('schema_pointer') })
    assert_equal(['/components/schemas/Dog/properties/bark'], schemer.validate(INVALID_DOG.merge('petType' => 'dog')).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(LIZARD))
    assert_equal(['/components/schemas/Lizard/properties/lovesRocks'], schemer.validate(INVALID_LIZARD).map { |error| error.fetch('schema_pointer') })
    assert(schemer.valid?(MONSTER))
    assert_equal(['/properties/hungry'], schemer.validate(INVALID_MONSTER).map { |error| error.fetch('schema_pointer') })
    refute(schemer.valid?(INVALID_MONSTER))
  end

  def test_discriminator_non_object_and_missing_property_name
    schemer = JSONSchemer.schema({ 'discriminator' => { 'propertyName' => 'x' } }, :meta_schema => JSONSchemer.openapi31)
    assert(schemer.valid?(1))
    refute(schemer.valid?({ 'y' => 'z' }))
  end

  def test_openapi31_formats
    schema = {
      'properties' => {
        'a' => { 'format' => 'int32' },
        'b' => { 'format' => 'int64' },
        'c' => { 'format' => 'float' },
        'd' => { 'format' => 'double' },
        'e' => { 'format' => 'password' }
      }
    }

    schemer = JSONSchemer.schema(schema, :meta_schema => JSONSchemer.openapi31)

    assert(schemer.valid_schema?)
    assert(schemer.valid?({ 'a' => 2.pow(31) }))
    refute(schemer.valid?({ 'a' => 2.pow(32) }))
    assert(schemer.valid?({ 'b' => 2.pow(63) }))
    refute(schemer.valid?({ 'b' => 2.pow(64) }))
    assert(schemer.valid?({ 'c' => 2.0 }))
    refute(schemer.valid?({ 'c' => 2 }))
    assert(schemer.valid?({ 'd' => 2.0 }))
    refute(schemer.valid?({ 'd' => 2 }))
    assert(schemer.valid?({ 'e' => 2 }))
    assert(schemer.valid?({ 'e' => 'anything' }))
  end

  def test_openapi30_formats
    schema = {
      'properties' => {
        'a' => { 'format' => 'int32' },
        'b' => { 'format' => 'int64' },
        'c' => { 'format' => 'float' },
        'd' => { 'format' => 'double' },
        'e' => { 'format' => 'password' },
        'f' => { 'format' => 'byte' },
        'g' => { 'format' => 'binary' },
        'h' => { 'format' => 'date' },
        'i' => { 'format' => 'date-time' }
      }
    }

    schemer = JSONSchemer.schema(schema, :meta_schema => JSONSchemer.openapi30)

    assert(schemer.valid_schema?)
    assert(schemer.valid?({ 'a' => 2.pow(31) }))
    refute(schemer.valid?({ 'a' => 2.pow(32) }))
    assert(schemer.valid?({ 'b' => 2.pow(63) }))
    refute(schemer.valid?({ 'b' => 2.pow(64) }))
    assert(schemer.valid?({ 'c' => 2.0 }))
    refute(schemer.valid?({ 'c' => 2 }))
    assert(schemer.valid?({ 'd' => 2.0 }))
    refute(schemer.valid?({ 'd' => 2 }))
    assert(schemer.valid?({ 'e' => 2 }))
    assert(schemer.valid?({ 'e' => 'anything' }))
    refute(schemer.valid?({ 'f' => '!' }))
    assert(schemer.valid?({ 'f' => 'IQ==' }))
    refute(schemer.valid?({ 'g' => '!' }))
    assert(schemer.valid?({ 'g' => '!'.b }))
    refute(schemer.valid?({ 'h' => '2001-02-03T04:05:06.123456789+07:00' }))
    assert(schemer.valid?({ 'h' => '2001-02-03' }))
    refute(schemer.valid?({ 'i' => '2001-02-03' }))
    assert(schemer.valid?({ 'i' => '2001-02-03T04:05:06.123456789+07:00' }))
  end

  def test_unsupported_openapi_version
    assert_raises(JSONSchemer::UnsupportedOpenAPIVersion) { JSONSchemer.openapi({ 'openapi' => '2.0' }) }
  end

  def test_unsupported_json_schema_dialect
    assert_raises(JSONSchemer::UnsupportedMetaSchema) { JSONSchemer.openapi({ 'openapi' => '3.1.0', 'jsonSchemaDialect' => 'unsupported' }) }
  end

  def test_openapi_documents
    draft4_dialect = JSONSchemer::Draft4::BASE_URI.to_s
    draft202012_dialect = JSONSchemer::Draft202012::BASE_URI.to_s
    base_document = {
      'openapi' => '3.1.0',
      'info' => {
        'title' => 'test document',
        'version' => '0.0.1'
      }
    }
    draft4_exclusive_maximum = {
      'maximum' => 1,
      'exclusiveMaximum' => true
    }
    draft4_implicit_document = base_document.merge(
      'components' => {
        'schemas' => {
          'draft4_exclusive_maximum' => draft4_exclusive_maximum
        }
      }
    )
    draft4_explicit_document = base_document.merge(
      'components' => {
        'schemas' => {
          'draft4_exclusive_maximum' => draft4_exclusive_maximum.merge(
            '$schema' => draft4_dialect
          )
        }
      }
    )
    draft202012_nested_implicit_document = base_document.merge(
      'components' => {
        'schemas' => {
          'draft202012_exclusive_maximum' => {
            '$schema' => draft202012_dialect,
            'exclusiveMaximum' => 1,
            '$defs' => {
              'draft4_exclusive_maximum' => draft4_exclusive_maximum
            }
          }
        }
      }
    )
    draft202012_nested_explicit_document = base_document.merge(
      'components' => {
        'schemas' => {
          'draft202012_exclusive_maximum' => {
            '$schema' => draft202012_dialect,
            'exclusiveMaximum' => 1,
            '$defs' => {
              'draft4_exclusive_maximum' => draft4_exclusive_maximum.merge(
                '$schema' => draft4_dialect
              )
            }
          }
        }
      }
    )

    refute(JSONSchemer.openapi(draft4_implicit_document).valid?)
    assert_equal(['number', '/properties/exclusiveMaximum'], JSONSchemer.openapi(draft4_implicit_document).validate.first.fetch_values('type', 'schema_pointer'))
    assert(JSONSchemer.openapi(draft4_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).valid?)
    assert_empty(JSONSchemer.openapi(draft4_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).validate.to_a)

    assert(JSONSchemer.openapi(draft4_explicit_document).valid?)
    assert_empty(JSONSchemer.openapi(draft4_explicit_document).validate.to_a)
    assert(JSONSchemer.openapi(draft4_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).valid?)
    assert_empty(JSONSchemer.openapi(draft4_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).validate.to_a)

    refute(JSONSchemer.openapi(draft4_implicit_document).schema('draft4_exclusive_maximum').valid_schema?)
    assert_raises(ArgumentError) { JSONSchemer.openapi(draft4_implicit_document).schema('draft4_exclusive_maximum').valid?(0) }
    assert_raises(ArgumentError) { JSONSchemer.openapi(draft4_implicit_document).schema('draft4_exclusive_maximum').valid?(1) }

    assert(JSONSchemer.openapi(draft4_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft4_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft4_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft4_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft4_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft4_exclusive_maximum').valid?(1))

    assert(JSONSchemer.openapi(draft4_explicit_document).schema('draft4_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft4_explicit_document).schema('draft4_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft4_explicit_document).schema('draft4_exclusive_maximum').valid?(1))

    refute(JSONSchemer.openapi(draft202012_nested_implicit_document).valid?)
    assert(JSONSchemer.openapi(draft202012_nested_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).valid?)

    refute(JSONSchemer.openapi(draft202012_nested_implicit_document).schema('draft202012_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft202012_nested_implicit_document).schema('draft202012_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft202012_nested_implicit_document).schema('draft202012_exclusive_maximum').valid?(1))
    refute(JSONSchemer.openapi(draft202012_nested_implicit_document).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid_schema?)
    assert_raises(ArgumentError) { JSONSchemer.openapi(draft202012_nested_implicit_document).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(0) }
    assert_raises(ArgumentError) { JSONSchemer.openapi(draft202012_nested_implicit_document).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(1) }

    # fixme: meta schema doesn't respect nested $schema
    refute(JSONSchemer.openapi(draft202012_nested_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft202012_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft202012_nested_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft202012_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft202012_nested_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft202012_exclusive_maximum').valid?(1))
    assert(JSONSchemer.openapi(draft202012_nested_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft202012_nested_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft202012_nested_implicit_document.merge('jsonSchemaDialect' => draft4_dialect)).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(1))

    assert(JSONSchemer.openapi(draft202012_nested_explicit_document).valid?)
    assert(JSONSchemer.openapi(draft202012_nested_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).valid?)

    # fixme: meta schema doesn't respect nested $schema
    refute(JSONSchemer.openapi(draft202012_nested_explicit_document).schema('draft202012_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft202012_nested_explicit_document).schema('draft202012_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft202012_nested_explicit_document).schema('draft202012_exclusive_maximum').valid?(1))
    assert(JSONSchemer.openapi(draft202012_nested_explicit_document).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft202012_nested_explicit_document).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft202012_nested_explicit_document).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(1))

    # fixme: meta schema doesn't respect nested $schema
    refute(JSONSchemer.openapi(draft202012_nested_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft202012_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft202012_nested_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft202012_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft202012_nested_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).schema('draft202012_exclusive_maximum').valid?(1))
    assert(JSONSchemer.openapi(draft202012_nested_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid_schema?)
    assert(JSONSchemer.openapi(draft202012_nested_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(0))
    refute(JSONSchemer.openapi(draft202012_nested_explicit_document.merge('jsonSchemaDialect' => draft4_dialect)).ref('#/components/schemas/draft202012_exclusive_maximum/$defs/draft4_exclusive_maximum').valid?(1))
  end

  def test_schemas
    discriminator_schema = {
      'oneOf' => [
        { '$ref' => '#/components/schemas/foo' },
        { '$ref' => '#/components/schemas/bar' }
      ],
      'discriminator' => {
        'propertyName' => 'type'
      }
    }
    openapi = {
      'openapi' => '3.1.0',
      'info' => {
        'title' => 'test',
        'version' => '0.0.1'
      },
      'components' => {
        'schemas' => {
          'foo' => true,
          'bar' => true,
          'no_schema' => discriminator_schema,
          'openapi31_schema' => discriminator_schema.merge(
            '$schema' => JSONSchemer::OpenAPI31::BASE_URI.to_s,
            '$defs' => {
              'draft202012_schema' => discriminator_schema.merge(
                '$schema' => JSONSchemer::Draft202012::BASE_URI.to_s
              )
            }
          ),
          'draft202012_schema' => discriminator_schema.merge(
            '$schema' => JSONSchemer::Draft202012::BASE_URI.to_s,
            '$defs' => {
              'openapi31_schema' => discriminator_schema.merge(
                '$schema' => JSONSchemer::OpenAPI31::BASE_URI.to_s
              )
            }
          )
        }
      }
    }

    document = JSONSchemer.openapi(openapi)

    assert(document.valid?)
    assert(document.schema('no_schema').valid?({ 'type' => 'foo' }))
    assert(document.schema('openapi31_schema').valid?({ 'type' => 'foo' }))
    refute(document.schema('draft202012_schema').valid?({ 'type' => 'foo' }))
    refute(document.ref('#/components/schemas/openapi31_schema/$defs/draft202012_schema').valid?({ 'type' => 'foo' }))
    assert(document.ref('#/components/schemas/draft202012_schema/$defs/openapi31_schema').valid?({ 'type' => 'foo' }))

    document = JSONSchemer.openapi(openapi.merge('jsonSchemaDialect' => JSONSchemer::Draft202012::BASE_URI.to_s))

    assert(document.valid?)
    refute(document.schema('no_schema').valid?({ 'type' => 'foo' }))
    assert(document.schema('openapi31_schema').valid?({ 'type' => 'foo' }))
    refute(document.schema('draft202012_schema').valid?({ 'type' => 'foo' }))
    refute(document.ref('#/components/schemas/openapi31_schema/$defs/draft202012_schema').valid?({ 'type' => 'foo' }))
    assert(document.ref('#/components/schemas/draft202012_schema/$defs/openapi31_schema').valid?({ 'type' => 'foo' }))
  end

  def test_access_mode
    schemer = JSONSchemer.schema({
      'properties' => {
        'read_only_true' => {
          'readOnly' => true
        },
        'read_only_false' => {
          'readOnly' => false
        },
        'write_only_true' => {
          'writeOnly' => true
        },
        'write_only_false' => {
          'writeOnly' => false
        }
      }
    })

    assert(schemer.valid_schema?)

    assert(schemer.valid?({ 'read_only_true' => 1, 'read_only_false' => 2, 'write_only_true' => 3, 'write_only_false' => 4 }))

    assert(schemer.valid?({ 'read_only_true' => 1 }))
    assert(schemer.valid?({ 'read_only_true' => 1 }, :access_mode => 'read'))
    refute(schemer.valid?({ 'read_only_true' => 1 }, :access_mode => 'write'))
    assert_includes(schemer.validate({ 'read_only_true' => 1 }, :access_mode => 'write').first.fetch('error'), 'readOnly')

    assert(schemer.valid?({ 'read_only_false' => 2 }))
    assert(schemer.valid?({ 'read_only_false' => 2 }, :access_mode => 'read'))
    assert(schemer.valid?({ 'read_only_false' => 2 }, :access_mode => 'write'))

    assert(schemer.valid?({ 'write_only_true' => 3 }))
    refute(schemer.valid?({ 'write_only_true' => 3 }, :access_mode => 'read'))
    assert(schemer.valid?({ 'write_only_true' => 3 }, :access_mode => 'write'))
    assert_includes(schemer.validate({ 'write_only_true' => 3 }, :access_mode => 'read').first.fetch('error'), 'writeOnly')

    assert(schemer.valid?({ 'write_only_false' => 4 }))
    assert(schemer.valid?({ 'write_only_false' => 4 }, :access_mode => 'read'))
    assert(schemer.valid?({ 'write_only_false' => 4 }, :access_mode => 'write'))

    schemer = JSONSchemer.schema({
      'required' => ['read_only_true', 'write_only_true'],
      'properties' => {
        'read_only_true' => {
          'readOnly' => true
        },
        'write_only_true' => {
          'writeOnly' => true
        }
      }
    })

    assert(schemer.valid_schema?)

    refute(schemer.valid?({ 'read_only_true' => 1 }))
    assert(schemer.valid?({ 'read_only_true' => 1 }, :access_mode => 'read'))
    refute(schemer.valid?({ 'write_only_true' => 2 }))
    assert(schemer.valid?({ 'write_only_true' => 2 }, :access_mode => 'write'))
  end

  def test_nullable
    schemer = JSONSchemer.openapi({
      'openapi' => '3.0.0',
      'components' => {
        'schemas' => {
          'test' => {
            'type' => 'string',
            'nullable' => true
          }
        }
      }
    }).schema('test')

    assert(schemer.valid_schema?)
    assert(schemer.valid?('1'))
    refute(schemer.valid?(1))
    assert(schemer.valid?(nil))

    schemer = JSONSchemer.openapi({
      'openapi' => '3.0.0',
      'components' => {
        'schemas' => {
          'test' => {
            'type' => 'string',
            'nullable' => false
          }
        }
      }
    }).schema('test')

    assert(schemer.valid_schema?)
    assert(schemer.valid?('1'))
    refute(schemer.valid?(1))
    refute(schemer.valid?(nil))
  end

  def test_openapi30
    openapi = {
      'openapi' => '3.0.0',
      'info' => {
        'title' => 'example',
        'version' => '0.0.1'
      },
      'components' => {
        'schemas' => {
          'test' => {
            'exclusiveMinimum' => true
          }
        }
      }
    }

    document = JSONSchemer.openapi(openapi)
    schemer = document.schema('test')

    assert_equal(['required', { 'missing_keys' => ['paths'] }], document.validate.first.values_at('type', 'details'))
    assert_equal(['dependencies', { 'missing_keys' => ['minimum'] }], schemer.validate_schema.first.values_at('type', 'details'))

    openapi = {
      'openapi' => '3.0.0',
      'info' => {
        'title' => 'example',
        'version' => '0.0.1'
      },
      'paths' => {},
      'components' => {
        'schemas' => {
          'test' => {
            'type' => 'string',
            'nullable' => true,
            'minimum' => 0,
            'exclusiveMinimum' => true
          }
        }
      }
    }

    document = JSONSchemer.openapi(openapi)
    schemer = document.schema('test')

    assert(document.valid?)
    assert(schemer.valid_schema?)
  end
end
