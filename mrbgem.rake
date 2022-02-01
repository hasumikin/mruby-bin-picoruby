MRuby::Gem::Specification.new 'mruby-bin-picoruby' do |spec|
  spec.license = 'MIT'
  spec.author  = 'HASUMI Hitoshi'
  spec.summary = 'picoruby executable'
  spec.add_dependency 'mruby-pico-compiler', github: 'hasumikin/mruby-pico-compiler'
  spec.add_dependency 'mruby-mrubyc', github: 'hasumikin/mruby-mrubyc'

  spec.cc.include_paths << "#{build.gems['mruby-mrubyc'].clone.dir}/repos/mrubyc/src"

  picoruby_src = "#{dir}/tools/picoruby/picoruby.c"
  picoruby_obj = objfile(picoruby_src.pathmap("#{build_dir}/tools/picoruby/%n"))

  file picoruby_obj => "#{dir}/tools/picoruby/picoruby.c" do |f|
    Dir.glob("#{dir}/tools/picoruby/*.c").map do |f|
      cc.run objfile(f.pathmap("#{build_dir}/tools/picoruby/%n")), f
    end
  end

  pico_compiler_srcs = %w(common compiler dump generator mrbgem my_regex
                          node regex scope stream token tokenizer)
  pico_compiler_objs = pico_compiler_srcs.map do |name|
    objfile("#{build.gems['mruby-pico-compiler'].build_dir}/src/#{name}")
  end

  mrubyc_dir = "#{build.gems['mruby-mrubyc'].dir}/repos/mrubyc"
  mrblib_obj = "#{build.gems['mruby-mrubyc'].build_dir}/src/mrblib.o"
  file mrblib_obj => "#{mrubyc_dir}/src/mrblib.c" do |f|
    cc.run f.name, f.prerequisites.first
  end
  file "#{mrubyc_dir}/src/mrblib.c" do |f|
    mrblib_sources = Dir.glob("#{mrubyc_dir}/mrblib/*.rb").join(' ')
    sh "#{build.mrbcfile} -B mrblib_bytecode -o #{mrubyc_dir}/src/mrblib.c #{mrblib_sources}"
  end

  exec = exefile("#{build.build_dir}/bin/picoruby")

  file exec => pico_compiler_objs + [mrblib_obj, picoruby_obj] do |f|
    mrubyc_objs = Dir.glob("#{build.gems['mruby-mrubyc'].build_dir}/src/**/*.o").reject do |o|
      o.end_with? "mrblib.o"
    end
    build.linker.run f.name, f.prerequisites + mrubyc_objs
  end

  build.bins << 'picoruby'
end
