Facter.add(:dynatrace_oneagent_programfiles) do
  setcode do
    confine :kernel => 'windows'
    if Dir.const_defined? 'PROGRAM_FILES'
      Dir::PROGRAM_FILES.gsub(%r{\\\s}, ' ').tr('/', '\\')
    elsif !ENV['ProgramFiles'].nil?
      ENV['ProgramFiles'].gsub(%r{\\\s}, ' ').tr('/', '\\')
    end
  end
end
