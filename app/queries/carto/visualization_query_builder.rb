# encoding: UTF-8

require 'active_record'

require_relative '../../models/carto/shared_entity'
require_dependency 'carto/bounding_box_utils'
require_dependency 'carto/uuidhelper'

# TODO: consider moving some of this to model scopes if convenient
class Carto::VisualizationQueryBuilder
  include Carto::UUIDHelper

  def self.user_public_tables(user)
    user_public(user).with_type(Carto::Visualization::TYPE_CANONICAL)
  end

  def self.user_public_visualizations(user)
    user_public(user).with_type(Carto::Visualization::TYPE_DERIVED)
  end

  def self.user_all_visualizations(user)
    new.with_user_id(user ? user.id : nil).with_type(Carto::Visualization::TYPE_DERIVED)
  end

  def self.user_public(user)
    new.with_user_id(user ? user.id : nil).with_privacy(Carto::Visualization::PRIVACY_PUBLIC)
  end

  PATTERN_ESCAPE_CHARS = ['_', '%'].freeze

  def initialize
    @include_associations = []
    @eager_load_associations = []
    @filtering_params = {}
  end

  def with_id_or_name(id_or_name)
    raise 'VisualizationQueryBuilder: id or name supplied is nil' if id_or_name.nil?

    if is_uuid?(id_or_name)
      with_id(id_or_name)
    else
      with_name(id_or_name)
    end
  end

  def with_id(id)
    @filtering_params[:id] = id
    self
  end

  def with_excluded_ids(ids)
    @filtering_params[:excluded_ids] = ids
    self
  end

  def without_synced_external_sources
    @filtering_params[:exclude_synced_external_sources] = true
    self
  end

  def without_imported_remote_visualizations
    @filtering_params[:exclude_imported_remote_visualizations] = true
    self
  end

  def without_raster
    @filtering_params[:excluded_kinds] ||= []
    @filtering_params[:excluded_kinds] << Carto::Visualization::KIND_RASTER
    self
  end

  def with_name(name)
    @filtering_params[:name] = name
    self
  end

  def with_user_id(user_id)
    @filtering_params[:user_id] = user_id
    self
  end

  def with_user_id_not(user_id)
    @filtering_params[:user_id_not] = user_id
    self
  end

  def with_privacy(privacy)
    @filtering_params[:privacy] = privacy
    self
  end

  def with_liked_by_user_id(user_id)
    @filtering_params[:liked_by_user_id] = user_id
    self
  end

  def with_shared_with_user_id(user_id)
    @filtering_params[:shared_with_user_id] = user_id
    self
  end

  def with_owned_by_or_shared_with_user_id(user_id)
    @filtering_params[:owned_by_or_shared_with_user_id] = user_id
    self
  end

  def with_prefetch_user(force_join = false)
    if force_join
      with_eager_load_of(:user)
    else
      with_include_of(:user)
    end
  end

  def with_prefetch_table
    nested_association = { map: :user_table }
    with_eager_load_of(nested_association)
  end

  def with_prefetch_dependent_visualizations
    inner_visualization = { visualization: { map: { layers: :layers_user_tables } } }
    nested_association = { map: { user_table: { layers: { maps: inner_visualization } } } }
    with_eager_load_of(nested_association)
  end

  def with_prefetch_permission
    nested_association = { permission: :owner }
    with_eager_load_of(nested_association)
  end

  def with_prefetch_external_source
    with_eager_load_of(:external_source)
  end

  def with_prefetch_synchronization
    with_eager_load_of(:synchronization)
    self
  end

  def with_types(types)
    @filtering_params[:types] = types.blank? ? nil : types
    self
  end

  alias with_type with_types

  def with_locked(locked)
    @filtering_params[:locked] = locked
    self
  end

  def with_current_user_id(user_id)
    @current_user_id = user_id
  end

  def with_order(order, direction = 'asc')
    @order = order.to_s
    @direction = direction.to_s
    self
  end

  def with_partial_match(tainted_search_pattern)
    @filtering_params[:tainted_search_pattern] = escape_characters_from_pattern(tainted_search_pattern)
    self
  end

  def escape_characters_from_pattern(pattern)
    pattern.chars.map { |c| PATTERN_ESCAPE_CHARS.include?(c) ? "\\" + c : c }.join
  end

  def with_tags(tags)
    @filtering_params[:tags] = tags
    self
  end

  def with_bounding_box(bounding_box)
    @filtering_params[:bounding_box] = bounding_box
    self
  end

  def with_display_name
    @filtering_params[:only_with_display_name] = true
    self
  end

  def with_organization_id(organization_id)
    @filtering_params[:organization_id] = organization_id
    self
  end

  # Published: see `Carto::Visualization#published?`
  def with_published
    @filtering_params[:only_published] = true
    self
  end

  def with_version(version)
    @filtering_params[:version] = version
    self
  end

  def build
    query = Carto::Visualization.all

    query = Carto::VisualizationQueryFilterer.new(query: query).filter(params: @filtering_params)

    query = query.includes(@include_associations)
    query = query.eager_load(@eager_load_associations)

    Carto::VisualizationQueryOrderer.new(query: query, user_id: @current_user_id).order(@order, @direction)
  end

  def build_paged(page = 1, per_page = 20)
    build.offset((page.to_i - 1) * per_page.to_i).limit(per_page.to_i)
  end

  private

  def with_include_of(association)
    @include_associations << association
    self
  end

  def with_eager_load_of(association)
    @eager_load_associations << association
    self
  end

end
