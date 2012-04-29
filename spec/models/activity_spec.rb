require 'spec_helper'

describe Activity do
  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }

  it "creates one when collection is created" do
    assert_activity 'collection_created',
      collection_id: collection.id,
      user_id: user.id,
      data: {name: collection.name},
      description: "Collection '#{collection.name}' was created"
  end

  it "creates one when layer is created" do
    Activity.delete_all

    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    assert_activity 'layer_created',
      collection_id: collection.id,
      layer_id: layer.id,
      user_id: user.id,
      data: {name: layer.name, fields: [{id: layer.fields.first.id, kind: 'text', code: 'foo', name: 'Foo'}]},
      description: "Layer '#{layer.name}' was created with fields: Foo (foo)"
  end

  context "layer changed" do
    it "creates one when layer's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

      Activity.delete_all

      layer.name = 'Layer2'
      layer.save!

      assert_activity 'layer_changed',
        collection_id: collection.id,
        layer_id: layer.id,
        user_id: user.id,
        data: {name: 'Layer1', changes: {'name' => ['Layer1', 'Layer2']}},
        description: "Layer 'Layer1' was renamed to '#{layer.name}'"
    end

    it "creates one when layer's field is added" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      layer.update_attributes! fields_attributes: [{kind: 'text', code: 'two', name: 'Two', ord: 2}]

      field = layer.fields.last

      assert_activity 'layer_changed',
        collection_id: collection.id,
        layer_id: layer.id,
        user_id: user.id,
        data: {name: 'Layer1', changes: {'added' => [{'id' => field.id, 'code' => field.code, 'name' => field.name, 'kind' => field.kind}]}},
        description: "Layer 'Layer1' changed: text field 'Two' (two) was added"
    end

    it "creates one when layer's field's code changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one1', name: 'One', ord: 1}]

      assert_activity 'layer_changed',
        collection_id: collection.id,
        layer_id: layer.id,
        user_id: user.id,
        data: {name: 'Layer1', changes: {'changed' => [{'id' => field.id, 'code' => ['one', 'one1'], 'name' => 'One', 'kind' => 'text'}]}},
        description: "Layer 'Layer1' changed: text field 'One' (one) code changed to 'one1'"
    end

    it "creates one when layer's field's name changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One1', ord: 1}]

      assert_activity 'layer_changed',
        collection_id: collection.id,
        layer_id: layer.id,
        user_id: user.id,
        data: {name: 'Layer1', changes: {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => ['One', 'One1'], 'kind' => 'text'}]}},
        description: "Layer 'Layer1' changed: text field 'One' (one) name changed to 'One1'"
    end

    it "creates one when layer's field's options changes" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'select_one', code: 'one', name: 'One', config: {'options' => ['1', '2', '3']}, ord: 1}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, code: 'one', name: 'One', kind: 'select_one', config: {'options' => ['4', '5', '6']}, ord: 1}]

      assert_activity 'layer_changed',
        collection_id: collection.id,
        layer_id: layer.id,
        user_id: user.id,
        data: {name: 'Layer1', changes: {'changed' => [{'id' => field.id, 'code' => 'one', 'name' => 'One', 'kind' => 'select_one', 'config' => [{'options' => ['1', '2', '3']}, {'options' => ['4', '5', '6']}]}]}},
        description: %(Layer 'Layer1' changed: select_one field 'One' (one) options changed from ["1", "2", "3"] to ["4", "5", "6"])
    end

    it "creates one when layer's field is removed" do
      layer = collection.layers.make user: user, name: 'Layer1', fields_attributes: [{kind: 'text', code: 'one', name: 'One', ord: 1}, {kind: 'text', code: 'two', name: 'Two', ord: 2}]

      Activity.delete_all

      field = layer.fields.last

      layer.update_attributes! fields_attributes: [{id: field.id, _destroy: true}]

      assert_activity 'layer_changed',
        collection_id: collection.id,
        layer_id: layer.id,
        user_id: user.id,
        data: {name: 'Layer1', changes: {'deleted' => [{'id' => field.id, 'code' => 'two', 'name' => 'Two', 'kind' => 'text'}]}},
        description: "Layer 'Layer1' changed: text field 'Two' (two) was deleted"
    end
  end

  it "creates one when layer is destroyed" do
    layer = collection.layers.make user: user, fields_attributes: [{kind: 'text', code: 'foo', name: 'Foo', ord: 1}]

    Activity.delete_all

    layer.destroy

    assert_activity 'layer_deleted',
      collection_id: collection.id,
      layer_id: layer.id,
      user_id: user.id,
      data: {name: layer.name},
      description: "Layer '#{layer.name}' was deleted"
  end

  it "creates one after running the import wizard" do
    Activity.delete_all

    csv_string = CSV.generate do |csv|
      csv << ['Name', 'Lat', 'Lon', 'Beds']
      csv << ['Foo', '1.2', '3.4', '10']
      csv << ['Bar', '5.6', '7.8', '20']
      csv << ['', '', '', '']
    end

    specs = [
      {name: 'Name', kind: 'name'},
      {name: 'Lat', kind: 'lat'},
      {name: 'Lon', kind: 'lng'},
      {name: 'Beds', kind: 'numeric', code: 'beds', label: 'The beds'},
      ]

    ImportWizard.import user, collection, csv_string
    ImportWizard.execute user, collection, specs

    assert_activity 'collection_imported',
      collection_id: collection.id,
      user_id: user.id,
      layer_id: collection.layers.first.id,
      data: {groups: 0, sites: 2},
      description: 'Import wizard: 0 groups and 2 sites were imported'
  end

  it "creates one after creating a site" do
    Activity.delete_all

    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {'beds' => 20}, user: user

    assert_activity 'site_created',
      collection_id: collection.id,
      user_id: user.id,
      site_id: site.id,
      data: {name: site.name, lat: site.lat, lng: site.lng, properties: site.properties},
      description: "Site '#{site.name}' was created"
  end

  it "creates one after creating a group" do
    Activity.delete_all

    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, location_mode: :manual, group: true, user: user

    assert_activity 'group_created',
      collection_id: collection.id,
      user_id: user.id,
      site_id: site.id,
      data: {name: site.name, lat: site.lat, lng: site.lng, location_mode: :manual},
      description: "Group '#{site.name}' was created"
  end

  it "creates one after importing a csv" do
    Activity.delete_all

    collection.import_csv user, %(
      id, type, name, lat, lng, parent, mode
      1, group, Group 1, 10, 20, , manual
      2, site, Site 1, 30, 40, 1,
    ).strip

    assert_activity 'collection_csv_imported',
      collection_id: collection.id,
      user_id: user.id,
      data: {groups: 1, sites: 1},
      description: "Import CSV: 1 group and 1 site were imported"
  end

  context "site changed" do
    it "creates one after changing one site's name" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {'beds' => 20}, user: user

      Activity.delete_all

      site.name = 'Bar'
      site.save!

      assert_activity 'site_changed',
        collection_id: collection.id,
        user_id: user.id,
        site_id: site.id,
        data: {name: 'Foo', changes: {'name' => ['Foo', 'Bar']}},
        description: "Site 'Foo' was renamed to 'Bar'"
    end

    it "creates one after changing one group's name" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, group: true, user: user

      Activity.delete_all

      site.name = 'Bar'
      site.save!

      assert_activity 'group_changed',
        collection_id: collection.id,
        user_id: user.id,
        site_id: site.id,
        data: {name: 'Foo', changes: {'name' => ['Foo', 'Bar']}},
        description: "Group 'Foo' was renamed to 'Bar'"
    end

    it "creates one after changing one site's location" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {'beds' => 20}, user: user

      Activity.delete_all

      site.lat = 15.1234567
      site.save!

      assert_activity 'site_changed',
        collection_id: collection.id,
        user_id: user.id,
        site_id: site.id,
        data: {name: site.name, changes: {'lat' => [10.0, 15.1234567], 'lng' => [20.0, 20.0]}},
        description: "Site '#{site.name}' changed: location changed from (10.0, 20.0) to (15.123457, 20.0)"
    end

    it "creates one after adding one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties['beds'] = 30
      site.save!

      assert_activity 'site_changed',
        collection_id: collection.id,
        user_id: user.id,
        site_id: site.id,
        data: {name: site.name, changes: {'properties' => [{}, {'beds' => 30}]}},
        description: "Site '#{site.name}' changed: 'beds' changed from (nothing) to 30"
    end

    it "creates one after changing one site's property" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {'beds' => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties['beds'] = 30
      site.save!

      assert_activity 'site_changed',
        collection_id: collection.id,
        user_id: user.id,
        site_id: site.id,
        data: {name: site.name, changes: {'properties' => [{'beds' => 20}, {'beds' => 30}]}},
        description: "Site '#{site.name}' changed: 'beds' changed from 20 to 30"
    end

    it "creates one after changing many site's properties" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {'beds' => 20, 'text' => 'foo'}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.properties['beds'] = 30
      site.properties['text'] = 'bar'
      site.save!

      assert_activity 'site_changed',
        collection_id: collection.id,
        user_id: user.id,
        site_id: site.id,
        data: {name: site.name, changes: {'properties' => [{'beds' => 20, 'text' => 'foo'}, {'beds' => 30, 'text' => 'bar'}]}},
        description: "Site '#{site.name}' changed: 'beds' changed from 20 to 30, 'text' changed from 'foo' to 'bar'"
    end

    it "doesn't create one after siglaning properties will change but they didn't change" do
      site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, properties: {'beds' => 20}, user: user

      Activity.delete_all

      site.properties_will_change!
      site.save!

      Activity.count.should eq(0)
    end
  end

  it "creates one after destroying a group" do
    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, location_mode: :manual, group: true, user: user

    Activity.delete_all

    site.destroy

    assert_activity 'group_deleted',
      collection_id: collection.id,
      user_id: user.id,
      site_id: site.id,
      data: {name: site.name},
      description: "Group '#{site.name}' was deleted"
  end

  it "creates one after destroying a site" do
    site = collection.sites.create! name: 'Foo', lat: 10.0, lng: 20.0, location_mode: :manual, user: user

    Activity.delete_all

    site.destroy

    assert_activity 'site_deleted',
      collection_id: collection.id,
      user_id: user.id,
      site_id: site.id,
      data: {name: site.name},
      description: "Site '#{site.name}' was deleted"
  end

  def assert_activity(kind, options = {})
    activities = Activity.all
    activities.length.should eq(1)

    activities[0].kind.should eq(kind)
    options.each do |key, value|
      activities[0].send(key).should eq(value)
    end
  end
end