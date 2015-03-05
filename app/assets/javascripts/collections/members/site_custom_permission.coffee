class @SiteCustomPermission
  constructor: (id, name, read, write, membership) ->
    @membership = membership
    @id = ko.observable id
    @name = ko.observable name
    @can_read = ko.observable read
    @can_write = ko.observable write
    @no_rights = ko.observable(!read)

    @noneChecked = ko.computed
      read: =>
        if @no_rights()
          "true"
        else
          "false"
      write: =>
        @no_rights true
        @can_read false
        @can_write false
        @membership.saveCustomSitePermissions()

    @readChecked = ko.computed
      read: =>
        if @can_read() and not @can_write()
          "true"
        else
          "false"
      write: =>
        @no_rights false
        @can_read true
        @can_write false
        @membership.saveCustomSitePermissions()

    @updateChecked = ko.computed
      read: =>
        if @can_write()
          "true"
        else
          "false"
      write: =>
        @no_rights false
        @can_read true
        @can_write true
        @membership.saveCustomSitePermissions()


  @findBySiteName: (sitePermissions, site_name) ->
    _.find sitePermissions, (perm) -> perm.name() == site_name

  @findBySiteId: (sitePermissions, site_id) ->
    _.find sitePermissions, (perm) -> perm.id() == site_id

  @summarizeNone: (sitePermissions) ->
    none_sites = []
    none_sites = ({ "id": p.id(), "name": p.name() } for p in sitePermissions when p.no_rights())
    { "all_sites": none_sites.length == 0 and sitePermissions.length ==0, "some_sites": none_sites }

  @summarizeRead: (sitePermissions) ->
    read_sites = []
    read_sites = ({ "id": p.id(), "name": p.name() } for p in sitePermissions when p.can_read())
    { "all_sites": read_sites.length == 0 and sitePermissions.length == 0, "some_sites": read_sites }

  @summarizeWrite: (sitePermissions) ->
    read_summary = @summarizeRead sitePermissions

    write_sites = []
    write_sites = ({ "id": p.id(), "name": p.name() } for p in sitePermissions when p.can_write())
    { "all_sites": write_sites.length == 0 and sitePermissions.length == 0 and read_summary["all_sites"], "some_sites": write_sites }

  # Expect "sitePermissions" to be an object like:
  #   "write":
  #     "all_sites": false
  #     "some_sites":[ {"id": "8376", "name": "Site 3"}]
  #   "read":
  #     "all_sites": true
  #     "some_sites": []
  @arrayFromJson: (sitePermissions, membership) ->
    window.startSites = sitePermissions
    write = (p) =>
      _.any(sitePermissions.write.some_sites, (s) -> s.id == p.id())

    not_in = (list, id) ->
      not _.any(list, (p) -> p.id() == id)

    return [] unless sitePermissions

    
    can_write_all = (not sitePermissions.write?) ||  sitePermissions.write.all_sites
    can_read_all = (not sitePermissions.read?) || sitePermissions.read.all_sites
    none_rights_all = (not sitePermissions.none?) || sitePermissions.none.all_sites
    return [] if can_write_all and can_read_all

    permissions = []

    unless none_rights_all
      permissions = (new SiteCustomPermission(site.id, site.name, false, false, membership) for site in sitePermissions.none.some_sites)
    # Create a SiteCustomPermission instance for each site listed in read.some_sites
    unless can_read_all
      permissions = permissions.concat(new SiteCustomPermission(site.id, site.name, true, can_write_all, membership) for site in sitePermissions.read.some_sites)

    unless can_write_all
      # Set write to true for all sites listed in write.some_sites that were also in read.some_sites
      permission.can_write(true) for permission in permissions when write(permission)

      # Create SiteCustomPermission instance for each site listed in write.some_sites that was not already created
      permissions = permissions.concat(new SiteCustomPermission(site.id, site.name, true, true,membership) for site in sitePermissions.write.some_sites when not_in(permissions, site.id))

    window.endSites = permissions
    permissions


