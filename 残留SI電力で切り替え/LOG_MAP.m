function CAL = LOG_MAP(lll,states)

lllcal = lll(1);
   for iii = 2:states
       log_MAP = log(1+exp(-1*(abs(lllcal-lll(iii)))));
         if lll(iii)>lllcal
              lllcal = lll(iii);
         end
         lllcal = lllcal+log_MAP;
   end
CAL = lllcal;

end