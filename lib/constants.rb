require_relative './Hesab/lib/hesab.rb'

module Const
  def self.G
    Adad.new 6.674e-11, :m, 3, :kg, -1, :s, -2
  end

  def self.h
    Adad.new 6.62607004e-34, :kg, 1, :m, 2, :s, -1
  end

  def self.c
    Adad.new 299792458, :m, 1 , :s, -1
  end

  def self.kB
    Adad.new 1.38064852e-23, :J, 1, :K, -1
  end

  def self.m_H
    Adad.new 1.67372e-27, :kg, 1
  end

  def self.m_He
    Adad.new 6.64648e-27, :kg, 1
  end

  def self.nu_HI
    Adad.new 3.288467e15, :Hz, 1
  end

  def self.nu_HeI
    Adad.new 5.945839e15, :Hz, 1
  end

  def self.nu_HeII
    Adad.new 1.315870e16, :Hz, 1
  end
end
