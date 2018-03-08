require_relative './lib/Hesab/lib/hesab.rb'
require_relative './lib/namelist.rb'
require_relative './lib/constants.rb'
require_relative './models/cold_clump_in_CGM.rb'

NAMELIST_NAME = './run.nml'

task :nml do
  nml = Namelist.new
  model = ColdClump.new(
    cosmo: :planck15,
    m: Adad.new(1.0e12, :Msun, 1),
    r: Adad.new(100.0, :kpc, 1),
    d: Adad.new(50.0, :kpc, 1),
    x: 0.75, y: 0.25,
    l: Adad.new(2.74e24, :W, 1, :Hz, -1),
    a: -1.7,
    s: Adad.new(40.0, :pc, 1),
    g: 128,
    tc: Adad.new(1.0e4, :K, 1),
  )

  model.describe

  nml.add_block('RUN_PARAMS', {
    cosmo: '.false.',
    hydro: '.true.',
    nrestart: '0',
    nremap: '10', # Frequency of load balancing (coarse time step)
    nsubcycle: '10*2',
    verbose: '.false.',
    rt: '.true.'
  })

  nml.add_block('UNIT_PARAMS', {
    units_density: Const::m_H.to(:g, 1).v, # Protons per cm^3
    units_time: Adad.new(1.0, :Myr, 1).to(:s, 1).v, # Myr
    units_length: Adad.new(1.0, :kpc, 1).to(:cm, 1).v, # kpc
  })

  nml.add_block('INIT_PARAMS', {
    nregion: model.regions[:x_center].length,
    region_type: "#{model.regions[:x_center].length}*\'square\'",
    x_center: model.regions[:x_center].map {|x| "#{x.to(:kpc, 1).v}"}.join(','),
    y_center: model.regions[:y_center].map {|y| "#{y.to(:kpc, 1).v}"}.join(','),
    z_center: model.regions[:z_center].map {|z| "#{z.to(:kpc, 1).v}"}.join(','),
    length_x: model.regions[:length_x].map {|x| "#{x.to(:kpc, 1).v}"}.join(','),
    length_y: model.regions[:length_y].map {|y| "#{y.to(:kpc, 1).v}"}.join(','),
    length_z: model.regions[:length_z].map {|z| "#{z.to(:kpc, 1).v}"}.join(','),
    exp_region: "#{model.regions[:x_center].length}*10",
    d_region: model.regions[:n].map {|n| "#{n.to(:cm, -3).v}"}.join(','),
    u_region: model.regions[:u].map {|u| "#{u}"}.join(','),
    v_region: model.regions[:v].map {|v| "#{v}"}.join(','),
    w_region: model.regions[:w].map {|w| "#{w}"}.join(','),
    p_region: model.regions[:p].map {|p| "#{p.to(:cm, -3, :kpc, 2, :Myr, -2).v}"}.join(','),
  })

  nml.add_block('AMR_PARAMS', {
    levelmin: Math::log2(model.simulation[:grid]).to_i,
    levelmax: Math::log2(model.simulation[:grid]).to_i,
    ngridtot: '1000000',
    nexpand: 1,
    boxlen: model.simulation[:size].to(:kpc, 1).v
  })

  nml.add_block('OUTPUT_PARAMS', {
    tout: model.output[:tout],
    foutput: model.output[:foutput],
    delta_tout: model.output[:delta_tout],
    tend: model.output[:tend],
  })

  nml.add_block('HYDRO_PARAMS', {
    gamma: 1.4,
    courant_factor: 0.8,
    scheme: '\'muscl\'',
    slope_type: 1
  })

  nml.add_block('RT_PARAMS', {
    X: model.regions[:X].v,
    Y: model.regions[:Y].v,
    rt_output_coolstats: '.true.', # std output thermochemistry statistics
    # Inter-cell flux function, less diffusive/spherically etric than GLF
    # also better at maintaining the directionality of radiation
    hll_evals_file: '\'./hll_evals.list\'',
    rt_courant_factor: '0.8',
    rt_c_fraction: '0.01',
    rt_smooth: '.true.',
    rt_otsa: '.true.', # H/He recombination does not emit ionising radiation
    rt_is_outflow_bound: '.true.',
    rt_is_init_xion: '.true.', # Only affects restart simulations
    rt_nsource: model.sources[:x_center].length,
    rt_source_type: "#{model.sources[:x_center].length}*\'square\'",
    rt_src_x_center: model.sources[:x_center].map {|x| "#{x.to(:kpc, 1).v}"}.join(','),
    rt_src_y_center: model.sources[:y_center].map {|y| "#{y.to(:kpc, 1).v}"}.join(','),
    rt_src_z_center: model.sources[:z_center].map {|z| "#{z.to(:kpc, 1).v}"}.join(','),
    rt_src_length_x: model.sources[:length_x].map {|x| "#{x.to(:kpc, 1).v}"}.join(','),
    rt_src_length_y: model.sources[:length_y].map {|y| "#{y.to(:kpc, 1).v}"}.join(','),
    rt_src_length_z: model.sources[:length_z].map {|z| "#{z.to(:kpc, 1).v}"}.join(','),
    rt_src_group: (0..model.sources[:x_center].length-1).map {|i| "#{i}"}.join(','),
    rt_n_source: model.sources[:dN_dtdA].map {|r| "#{r.to(:s, -1, :cm, -2).v}"}.join(','),
    rt_u_source: model.sources[:u].map {|u| "#{u}"}.join(','),
    rt_v_source: model.sources[:v].map {|v| "#{v}"}.join(','),
    rt_w_source: model.sources[:w].map {|w| "#{w}"}.join(','),
  })

  nml.add_block('RT_GROUPS', {
    groupL0: '13.60,24.59,54.42',
    group_egy: '18.85, 35.08, 65.67',
    groupL1: '24.59,54.42,0.0',
    spec2group: '1, 2, 3'
  })

  nml.add_block('BOUNDARY_PARAMS', {
    nboundary: model.boundaries[:ibound_min].length,
    ibound_min: model.boundaries[:ibound_min].map {|i| "#{i}"}.join(','),
    jbound_min: model.boundaries[:jbound_min].map {|j| "#{j}"}.join(','),
    kbound_min: model.boundaries[:kbound_min].map {|k| "#{k}"}.join(','),
    ibound_max: model.boundaries[:ibound_max].map {|i| "#{i}"}.join(','),
    jbound_max: model.boundaries[:jbound_max].map {|j| "#{j}"}.join(','),
    kbound_max: model.boundaries[:kbound_max].map {|k| "#{k}"}.join(','),
    bound_type: model.boundaries[:bound_type].map {|t| "#{t}"}.join(','),
  })

  nml.write(NAMELIST_NAME)
  sh "$EDITOR #{NAMELIST_NAME}"
end

task :plot do

end
