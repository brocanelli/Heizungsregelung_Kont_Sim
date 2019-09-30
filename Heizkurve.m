function[T_heater] = Heizkurve(T_inside,T_outside, C1, C2)
%this function finds the ideal temperature of the fluid in the heating
%circuit, or generically in the heater, starting from inside and outside
%temperature and from the two parameters C1 and C2 which are the steepness
%and parallel/vertical slide of the curve.

T_heater = T_inside + C1*sqrt(T_inside-T_outside)+C2;

end
