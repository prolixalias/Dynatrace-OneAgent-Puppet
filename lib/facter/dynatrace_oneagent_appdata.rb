Facter.add(:dynatrace_oneagent_appdata) do
  setcode do
    confine :kernel => 'windows'
    if Dir.const_defined? 'COMMON_APPDATA'
      Dir::COMMON_APPDATA.gsub(%r{\\\s}, ' ').tr('/', '\\')
    elsif !ENV['ProgramData'].nil?
      ENV['ProgramData'].gsub(%r{\\\s}, ' ').tr('/', '\\')
    end
  end
end
