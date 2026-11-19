# Thank you, Claude!
require "trailblazer"

if ENV["VERSION"] == "3"

# TODO: make this somewhere automatically! operation/macro, maybe?
  [
  # Acti[Trailblazer::Activity::FastTrack,  # DISCUSS: remove?
    Trailblazer::Operation # we need to add this because we're using :adds, so both normalizers get updated.
  ].each do |topology|
    _, _, builder, helpers_module = Trailblazer::Activity::DSL::Topology.build(
      builder: topology.config.builder,
      default_options: {},
      **Trailblazer::Macro::TOPOLOGY_BUILD_OPTIONS # :helpers and :adds
    )

    topology.config.builder = builder
    topology.include helpers_module
  end

  [
  # Acti[Trailblazer::Activity::FastTrack,  # DISCUSS: remove?
    Trailblazer::Operation # we need to add this because we're using :adds, so both normalizers get updated.
  ].each do |topology|
    _, _, builder, helpers_module = Trailblazer::Activity::DSL::Topology.build(
      builder: topology.config.builder,
      default_options: {},
      **Trailblazer::Macro::Contract::TOPOLOGY_BUILD_OPTIONS # :helpers and :adds
    )

    topology.config.builder = builder
    topology.include helpers_module
  end
end



require "reform/form/dry"
# --- Plain domain objects -----------------------------------------------------

User = Struct.new(:name, :admin) do
  def admin? = admin
end

Song = Struct.new(:title, :length) do
  def save = true
end

# --- Contract -----------------------------------------------------------------

class SongForm < Reform::Form
  feature Reform::Form::Dry

  property :title
  property :length

  validation do
    params do
      required(:title).filled(:string)
      required(:length).filled(:integer, gt?: 0)
    end
  end
end

# --- Level 3 (innermost) ------------------------------------------------------

class Song::Notify < Trailblazer::Operation
  step :build_message
  step :deliver
  step :record_delivery

  def build_message(ctx, **)    = true  # pseudo
  def deliver(ctx, **)          = true  # pseudo
  def record_delivery(ctx, **)  = true  # pseudo
end

# --- Level 2 ------------------------------------------------------------------

class Song::PostProcess < Trailblazer::Operation
  step :normalize_title
  step :index_for_search
  step Subprocess(Song::Notify), id: :a
  step :invalidate_cache

  def normalize_title(ctx, **)   = true  # pseudo
  def index_for_search(ctx, **)  = true  # pseudo
  def invalidate_cache(ctx, **)  = true  # pseudo
end

# --- Level 1 (entry point) ----------------------------------------------------

class Song::Create < Trailblazer::Operation
  step Policy::Guard(->(ctx, current_user:, **) { current_user.admin? })
  step :model,
    In() => [:params], Out() => [:model]
  step Contract::Build(constant: SongForm)
  step Contract::Validate(key: :song)
  step Contract::Persist()
  step Subprocess(Song::PostProcess), id: :b,
    In() => :my_input_for_post_process,
    Out() => :my_output_for_post_process
  step :audit_log
  # step :bla

  def my_input_for_post_process(ctx, model:, **)
    {bogus: true}
  end

  def my_output_for_post_process(ctx, **)
    {}
  end

  def model(ctx, **)
    ctx[:model] = Song.new
  end

  def audit_log(ctx, **) = true  # pseudo

    def bla(ctx, **)
      puts "@@@@@ #{ctx.inspect}"
      true
    end
end

# --- Quick smoke test ---------------------------------------------------------

# if $PROGRAM_NAME == __FILE__
#   admin = User.new("alice", true)
#   guest = User.new("bob", false)
#   valid = { song: { title: "Roxanne", length: 190 } }

#   ok      = Song::Create.(params: valid, current_user: admin)
#   invalid = Song::Create.(params: { song: { title: "", length: 0 } }, current_user: admin)
#   denied  = Song::Create.(params: valid, current_user: guest)
