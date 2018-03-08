require_relative './../lib/Hesab/lib/hesab.rb'
require_relative './../lib/cosmo.rb'
require_relative './../lib/constants.rb'

class ColdClump

    # Cross section of each group and species
    @@cs = [
      [
        Adad.new(3.0e-18, :cm, 2), # nu_HI & HI
        Adad.new(0.0, :cm, 2), # nu_HI & HeI
        Adad.new(0.0, :cm, 2) # nu_HI & HeII
      ],
      [
        Adad.new(5.7e-19, :cm, 2), # nu_HeI & HI
        Adad.new(4.5e-18, :cm, 2), # nu_HeI & HeI
        Adad.new(0.0, :cm, 2) # nu_HeI & HeII
      ],
      [
        Adad.new(7.9e-20, :cm, 2), # nu_HeII & HI
        Adad.new(1.2e-18, :cm, 2), # nu_HeII & HeI
        Adad.new(1.1e-18, :cm, 2) # nu_HeII & HeII
      ],
    ]

  # Initializing the model
  #
  # === Attributes
  # +cosmo+:: The cosmology
  # +m+:: Halo mass (M_sun)
  # +r+:: Halo radius (kpc)
  # +d+:: Clump distance (kpc)
  # +x+:: Hydrogen fraction
  # +y+:: Helium fraction
  # +l+:: QSO's luminosity at 912A (Watt per second)
  # +a+:: Slope of the QSO's power law spectrum
  # +s+:: Box size
  # +g+:: Grid dimension
  # +tc+:: Temperature of cold region
  def initialize(cosmo: nil, m: nil, r: nil, d: nil, x: nil, y: nil,
    l: nil, a: nil, s: nil, g: nil, tc: nil)
    # Cosmology
    @cosmo = Cosmo.new(cosmo || :planck15)
    f_gas = @cosmo.Ob / @cosmo.Om

    # Halo
    @M = m.is_a?(Adad) ? m : Adad.new(m || 1.0e12, :Msun, 1)
    @R = r.is_a?(Adad) ? r : Adad.new(r || 100.0, :kpc, 1)

    # Clump
    @d = d.is_a?(Adad) ? d : Adad.new(d || 50.0, :kpc, 1)
    @X = Adad.new x || 0.75, :m, 1, :m, -1
    @Y = Adad.new y || 0.25, :m, 1, :m, -1
    mu = @X + (@Y * 4)

    # Source
    @nu_912 = Adad.new 3.287198e15, :Hz, 1
    # [defaults from Lusso et al. 2015]
    @L_912 = l.is_a?(Adad) ? l : Adad.new(l || 2.74e24, :W, 1, :Hz, -1)
    @a = a || -1.7

    # Geometry
    @size = s.is_a?(Adad) ? s : Adad.new(b || 1.0, :kpc, 1)
    @grid = g || 128

    # Temperature of regions
    @T = [
      ((Const.G * @M / @R) * (mu * Const.m_H / Const.kB) / 3.0).to(:K, 1), # Hot
      tc.is_a?(Adad) ? tc : Adad.new(tc || 1.0e4, :K, 1), # Cold
    ]

    # Number densities of regions
    n_H = @M / (@R**3 * (4.0/3) * Math::PI) * f_gas / (mu * Const::m_H)
    @n = [
      n_H, # Hot
      @T[0] / @T[1] * n_H, # Cold region in pressure equilibrium
    ]

    # Pressure of regions
    @p = [
      @n[0] * Const.kB * @T[0] / Const.m_H, # Hot
      @n[1] * Const.kB * @T[1] / Const.m_H, # Cold
    ]

    # Frequency bins
    nu = [
      Adad.new(4.557912e15, :Hz, 1),
      Adad.new(8.482310e15, :Hz, 1),
      Adad.new(1.587894e16, :Hz, 1),
    ]

    # Brightness of 912A photons at the position of the clump (Normalized)
    b_912 = @L_912 / (@nu_912**@a * (@a+1)) / (@d**2 * 4 * Math::PI)

    # Photon flux at the position of the clump
    @dN_dtdA = [
      b_912 * (Const.nu_HeI**(@a+1) - Const.nu_HI**(@a+1)) / (Const.h * nu[0]),
      b_912 * (Const.nu_HeII**(@a+1) - Const.nu_HeI**(@a+1)) / (Const.h * nu[1]),
      b_912 * (Const.nu_HeII**(@a+1) * -1) / (Const.h * nu[2]),
    ].map { |i| i.simplify! }
  end

  # Printing the variables of the model
  def describe
    p "Cosmology: #{@cosmo}"
    p "Halo mass: #{@M.v} #{@M.u}"
    p "Halo radius: #{@R.v} #{@R.u}"
    p "Clump distance: #{@d.v} #{@d.u}"
    p "Clump temperature: #{@T[1].v} #{@T[1].u}"
    p "X: #{@X.v}"
    p "Y: #{@Y.v}"
    p "912A luminosity: #{@L_912.v} #{@L_912.u}"
    p "Power law slope: #{@a}"
    p "Box size: #{@size.v} #{@size.u}"
    p "Grid: #{@grid}"
  end

  # Regions
  def regions
    {
      x_center: [@size * 0.05, @size * 0.55],
      y_center: [@size / 2,    @size / 2],
      z_center: [@size / 2,    @size / 2],
      length_x: [@size * 0.1,  @size * 0.9],
      length_y: [@size,        @size],
      length_z: [@size,        @size],
      u: [0.0, 0.0], # x-direction velocities
      v: [0.0, 0.0], # y-direction velocities
      w: [0.0, 0.0], # z-direction velocities
      n: @n, # Number densities
      T: @T, # Temperatures
      p: @p, # Pressures
      X: @X,
      Y: @Y,
    }
  end

  # Boundary conditions
  def boundaries
    {
      ibound_min: [-1, +1, -1, -1, -1, -1],
      jbound_min: [0,   0, -1, +1, -1, -1],
      kbound_min: [0,   0,  0,  0, -1, +1],
      ibound_max: [-1, +1, +1, +1, +1, +1],
      jbound_max: [0,   0, -1, +1, +1, +1],
      kbound_max: [0,   0,  0,  0, -1, +1],
      bound_type: [2,   2,  0,  0,  0,  0],
    }
  end

  # Sources geometries and directionality
  def sources
    {
      x_center: [@size * 0.005, @size * 0.005, @size * 0.005],
      y_center: [@size * 0.5,   @size * 0.5,   @size * 0.5],
      z_center: [@size * 0.5,   @size * 0.5,   @size * 0.5],
      length_x: [@size * 0.01,  @size * 0.01,  @size * 0.01],
      length_y: [@size,         @size,         @size],
      length_z: [@size,         @size,         @size],
      u: [1.0, 1.0, 1.0],
      v: [0.0, 0.0, 0.0],
      w: [0.0, 0.0, 0.0],
      dN_dtdA: @dN_dtdA,
    }
  end

  def simulation
    {
      size: @size,
      grid: @grid,
    }
  end

  def output
    {
      tout: 0,
      foutput: 3000,
      delta_tout: Adad.new(20.0, :yr, 1).to(:Myr, 1).v,
      tend: Adad.new(2.0, :Myr, 1).v,
    }
  end
end
