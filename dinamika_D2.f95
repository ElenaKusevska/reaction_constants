program partition
implicit none

!---------------------------------------
! calculate the rate constant
! for the reaction D + H2 -> DH + H:
!---------------------------------------

integer, parameter :: dp = SELECTED_REAL_KIND(15)
integer :: i !counter

!------------
! constants:
!------------

real(dp), parameter :: boltzmann = 1.380648813D-23 ![m^(2)kg/(s^(2)K)]
real(dp), parameter :: h = 6.626069573D-34 ![m^(2)kg/s]
real(dp), parameter :: pi = 3.141592654
real(dp), parameter :: c = 299792458  !speed of light - [m/s]
real(dp), parameter :: Ea = 9.7 ![kcal/mol]
real(dp), parameter :: kcaltoJ = 4184 !conversion factor
real(dp), parameter :: angstrom = 1D-10 !convert angstroms to meters
real(dp), parameter :: mp = 1.672621777D-27 !mass of proton - [kg]
real(dp), parameter :: mn = 1.674927351D-27 !mass of neutron - [kg]
real(dp), parameter :: me = 9.10938291D-31 !mass of electron - [kg]
real(dp), parameter :: symm = 2 !statistical factor.
real(dp), parameter :: R = 8.314462175 !gas constant [J/(Kmol)]
real(dp), parameter :: N = 6.0221412927D+23!avogadro's number - [mole^(-1)]

!--------------
! variables:
!--------------

real, parameter :: V = 1 !volume -> [m^3]
real(dp) :: E, vim, elec !Energy to cross the 
                           !barrier and imaginary frequency
                           !and electronic partition function
real(dp), dimension(701) :: k, Q, T, trans, vib, rot! rate constant, 
                                 !temperature and partition functions 
                                 !for the reaction
real(dp), parameter :: eD = 2, eH2 = 1, eDHH = 2 !electronic partition 
                                                   !functions 
real(dp), dimension(701) :: dG, dH, dS, KC, wigner, kcorr 
                                 !Gibbs free energy, enthalpy and 
                                 !entropy of the transition state
                                 !reaction, the equilibrium constant and 
                                 !the wigner correction.                  

! Deuterium:
real(dp) :: mD !mass of deuterium
real(dp), dimension(701) :: qtrans !translational partition function of 
                                       !deuterium.

! Hydrogen molecule:
real(dp), dimension(701) :: vibH2, rotH2, transH2
                     !translational, rotational and vibrational partition
                     !function of hydrogen
real(dp) :: f !vibrational frequency [s^(-1)].
real(dp) :: mH, mH2, rH2 !mass of hydrogen atom, mass and 
                              !radius of hydrogen molecule
real(dp) :: IH2 ! angular momentum
real(dp) :: ZPEH2 !ZP correction

! D-H-H:
real(dp), dimension(701) :: DHHrot, DHHvib, DHHtrans, QDHH
real(dp) :: IDHH, rDHH, mDHH !rotational momentum, distances and 
                                 !mass for the transition state
real(dp) :: vDHH1, vDHH2 !vibrational frequencies, ali toa vtoroto 
                              !moze da bide greska
real(dp) :: ZPEDHH !zero point correction

!----------------------------------------
! define some values first:
!----------------------------------------

vim = (850.)*c *(100.) !imaginary frequency of the 
                              !transition state [s^(-1)]
elec = eDHH/(eH2*eD) !electronic partition f-tion.
mD = mp + mn + me ![kg] - mass of deuterium
f = (4401.) * c * (100.)  
mH = mp + me !mass of hydrogen [kg] 
mH2 = (2.)*(mp + me) !mass of hydrogen molecule [kg]
rH2 = 0.741*angstrom !distance between hydrogen atoms - [m]
IH2 = ((mH*mH)/(mH+mH))*(rH2**(2.)) !moment of inertia of hydrogen molecule
ZPEH2 = (h*f*N)/(2.)

! moment of inertia and mass of transition state:
rDHH = 0.929*angstrom
IDHH = mD*(rDHH**(2.)) + mH*(rDHH**(2.)) - ((mD*rDHH-mH*rDHH)**(2.))/(mD+mH+mH)
mDHH = mD + mH + mH
vDHH1 = (1780.)*c*(100.)
vDHH2 = (861.)*c*(100.)
ZPEDHH = Ea*kcaltoJ + N*(0.5)*(h*vDHH1 + (2.)*h*vDHH2) 

E = (ZPEDHH-ZPEH2)

open (unit=1, file='results_D2.txt', status='new', action='write')
write(1,*) 'T', '	', 'k', '	', 'Kc', '	', 'G', '	', 'H', '	', 'S',&
   '	', 'wigner', '	', 'kcorr'

!----------------------------------
! calculate partition function:
!----------------------------------

do i = 1, 701
   T(i) = i + 299

   !----------------------------------------------------------Deuterium:
   !--------------------------------------------------------------------

   qtrans(i) = ((((2.)*pi*mD*boltzmann*T(i))**(3./2.))/(h**(3.)))*V

   !--------------------------------------------------Hydrogen molecule:
   !--------------------------------------------------------------------

   vibH2(i) = (1.) / ((1.) - exp(-h*f/(boltzmann*T(i))))
   rotH2(i) = ((8.)*(pi**(2.))*IH2*boltzmann*T(i))/h !In the presentation
   !(8.)*(pi**(2.))*IH2*boltzmann*T(i) is under aroot
   !but everywhere else I looked, it wasn't, so 
   !I used that formula. 

   transH2(i) = (((2.)*pi*mH2*boltzmann*T(i))**(3./2.))/(h**(3.))*V

   !--------------------------------------------------------------D-H-H:
   !--------------------------------------------------------------------

   DHHrot(i) = ((8.)*(pi**(2.))*IDHH*boltzmann*T(i))/h
   DHHvib(i) = ((1.) / ((1.) - exp(-h*vDHH2/(boltzmann*T(i))))**(2.))*&
   ((1.) / ((1.) - exp(-h*vDHH1/(boltzmann*T(i)))))
   DHHtrans(i) = (((2.)*pi*mDHH*boltzmann*T(i))**(.3/.2))/(h**(3.))*V

   !---------------------------------------------------------value of k:
   !--------------------------------------------------------------------

   rot(i) = DHHrot(i)/rotH2(i)
   trans(i) = DHHtrans(i)/(qtrans(i)*transH2(i))
   vib(i) = DHHvib(i)/vibH2(i)
   Q(i) = rot(i)*vib(i)*trans(i)*elec
   KC(i) = Q(i)*N*(1000.)*exp(-(E/(R*T(i)))) !L/mol
   k(i) = symm*((boltzmann*T(i))/h)*Q(i)*exp(-(E/(R*T(i))))*N*1000
                                          !k(i) -> [L/mols]
   dG(i) = -R*T(i)*LOG(KC(i))
   dH(i) = E - (2.)*R*T(i)
   dS(i) = (dH(i)-dG(i))/T(i)
   wigner(i) = (1.) + ((1./24.))*((h*vim)/(boltzmann*T(i)))**(2.)
   kcorr(i) = k(i)*wigner(i)

   write(1,*) T(i), k(i), Kc(i), dG(i), dH(i), dS(i), wigner(i), kcorr(i)
end do

end program partition
