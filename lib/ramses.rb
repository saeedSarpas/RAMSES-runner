require_relative './makefile.rb'

class RamsesMakefile

  # Generating ramses Makefile
  #
  # === Attributes
  # +nvec+:: NVECTOR
  # +nd+:: NDIM
  # +np+:: NPRE (Floating-point precision)
  # +nvar+:: NVAR
  # +ne+:: NENERgy vars used in hydro or mhd solver
  # +s+:: SOLVER (:hydro, :mhd, :rhd)
  # +p+:: PATCH
  # +g+:: GRACLE
  # +e+:: EXECutable name
  # +ni+:: NIONS (Ionisation species)
  # +ng+:: NGROUPS (Number of photon groups)
  # +t+:: type of simulation, e.g. :rt, etc.
  def initialize(nvec: nil, nd: nil, np: nil, nvar: nil, ne: nil, s: nil,
    p: nil, g: nil, e: nil, ni: nil, ng: nil, t: nil)
    @nvector = nvec || 64
    @ndim = nd || 3
    @npre = np || 8
    @nvar = nvar || 8
    @nener = ne || 0
    @solver = s || :rhd
    @patch = p || ''
    @grackle = g || false
    @exec = e || 'ramses'
    @nions = ni || 3
    @ngroups = ng || ngroups
    @type = t || :rt
  end

  # Print relevant variables
  def describe
    p "NVECTOR: #{@nvector}"
    p "NDIM: #{@ndim}"
    p "NPRE: #{@npre}"
    p "NVAR: #{@nvar}"
    p "NENER: #{@nener}"
    p "SOLVER: #{@solver}"
    p "PATCH: #{@patch}"
    p "GRACKLE: #{@grackle}"
    p "EXEC: #{@exec}"
    p "NIONS: #{@nions}"
    p "NGROUPS: #{@ngroups}"
    p "TYPE: #{@type}"
  end

  # Generating a makefile
  def makefile(path)
    m = Makefile.new

    m.set 'F90', 'mpif90 -frecord-marker=4 -O3 -ffree-line-length-none -g -fbacktrace'
    m.set 'FFLAGS', '-x f95-cpp-input $(DEFINES)'

    m.define 'NVECTOR', @nvector
    m.define 'NDIM', @ndim
    m.define 'NPRE', @npre
    m.define 'NENER', @nener
    m.define 'SOLVER', @solver.to_s
    m.define 'grackle', 1 if @grackle

    if @type == :rt
      m.define 'RT', 1
      m.define 'NIONS', @nions
      m.define 'NGROUPS', @ngroups
    end

    m.define 'NVAR', @nvar

    m.set 'GRACKLE', 1 if @grackle
    m.set 'PATCH', @patch
    m.set 'EXEC', @exec

    m.set 'GITBRANCH', '$(shell git rev-parse --abbrev-ref HEAD)'
    m.set 'GITHASH', "$(shell git log --pretty=format:'%H' -n 1)"
    m.set 'GITREPO', '$(shell git config --get remote.origin.url)'
    m.set 'BUILDDATE', "$(shell date +\"%D-%T\")"

    m.set 'MOD', 'mod'
    m.set 'LIBMPI', '-L/usr/lib -lmpi'

    if @grackle
      m.set 'LIBS_GRACKLE', 'L$(HOME)/.local/lib -lgrackle -lhdf5 -lz -lgfortran -ldl'
      m.set 'LIBS_OBJ', '-I$(HOME)/.local/include -DCONFIG_BFLOAT_8 -DH5_USE_16_API -fPIC'
    end

    m.set 'LIBS', '$(LIBMPI) $(LIBS_GRACKLE)'
    m.set 'VPATH', '$(shell [ -z $(PATCH) ] || find $(PATCH) -type d):' \
    '../$(SOLVER):../aton:../hydro:../pm:../poisson:../amr:../io:../rt'

    m.set 'AMROBJ', _ls_obj('amr')
    m.set 'EXTRAOBJ', 'dump_utils.o write_makefile.o write_patch.o'
    m.set 'PMOBJ', _ls_obj('pm')
    m.set 'POISSONOBJ', _ls_obj('poisson')
    m.set 'HYDROOBJ', _ls_obj('hydro')
    m.set 'RTOBJ', _ls_obj('rt') if @type == :rt

    # MODOBJ are just pre-required objects for compiling other source codes
    m.set 'MODOBJ', 'amr_parameters.o amr_commons.o random.o ' \
    'pm_parameters.o pm_commons.o poisson_parameters.o dump_utils.o ' \
    'poisson_commons.o hydro_parameters.o hydro_commons.o cooling_module.o ' \
    'bisection.o sparse_mat.o clfind_commons.o gadgetreadfile.o ' \
    'write_makefile.o write_patch.o write_gitinfo.o'
    if @type == :rt
      m.extend 'MODOBJ', 'rt_parameters.o rt_hydro_commons.o coolrates_' \
      'module.o rt_spectra.o rt_cooling_module.o rt_flux_module.o'
    end
    m.extend 'MODOBJ', 'grackle_parameters.o' if @grackle

    m.set 'AMRLIB', '$(AMROBJ) $(HYDROOBJ) $(PMOBJ) $(POISSONOBJ) $(EXTRAOBJ)'
    m.extend 'AMRLIB', '$(RTOBJ)' if @type == :rt

    m.set 'ATON_MODOBJ', 'timing.o radiation_commons.o rad_step.o'
    m.set 'ATON_OBJ', _ls_obj('aton')
    m.extend 'ATON_OBJ', '../aton/atonlib/libaton.a'

    m.plain 'sinclude $(PATCH)/Makefile'

    m.rule 'ramses', '$(MODOBJ) $(AMRLIB) ramses.o',
    '$(F90) $(AMRLIB) -o $(EXEC)$(NDIM)d $(LIBS)',
    'rm write_makefile.f90 write_patch.f90'

    m.rule 'ramses_aton', '$(MODOBJ) $(ATON_MODOBJ) $(AMRLIB) $(ATON_OBJ) ramses.o', \
    '$(F90) $(ATON_MODOBJ) $(AMRLIB) $(ATON_OBJ) -o $(EXEC)$(NDIM)d $(LIBS) $(LIBCUDA)', \
    'rm write_makefile.f90 write_patch.f90'

    m.rule 'write_gitinfo.o', 'FORCE',
    "$(F90) $(FFLAGS) -DPATCH=\'\"$(PATCH)\"\' " \
    "-DGITBRANCH=\'\"$(GITBRANCH)\"\' -DGITHASH=\'\"$(GITHASH)\"\' " \
    "-DGITREPO=\'\"$(GITREPO)\"\' -DBUILDDATE=\'\"$(BUILDDATE)\"\' " \
    "-c ../amr/write_gitinfo.f90 -o $@"

    m.rule 'write_makefile.o', 'FORCE',
    '../utils/scripts/cr_write_makefile.sh $(MAKEFILE_LIST)',
    '$(F90) $(FFLAGS) -c write_makefile.f90 -o $@'

    m.rule 'write_patch.o', 'FORCE', \
    '../utils/scripts/cr_write_patch.sh $(PATCH)',
    '$(F90) $(FFLAGS) -c write_patch.f90 -o $@'

    m.rule '%.o', '%.F', '$(F90) $(FFLAGS) -c $^ -o $@ $(LIBS_OBJ)'
    m.rule '%.o', '%.f90', '$(F90) $(FFLAGS) -c $^ -o $@ $(LIBS_OBJ)'
    m.rule 'FORCE', '', ''
    m.rule 'clean', '', 'rm -f *.o *.$(MOD)'

    m.write(path)
  end

  def _ls_obj(dir)
    `cd ./ramses/#{dir} && ls *.f90`.gsub!("f90\n", 'o ')
  end
end
