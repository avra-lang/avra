import resource, subprocess, sys, time
out=open(sys.argv[1],'w'); err=open(sys.argv[2],'w')
t=time.time()
subprocess.run(sys.argv[3:],stdout=out,stderr=err)
w=time.time()-t
r=resource.getrusage(resource.RUSAGE_CHILDREN)
print("wall %.2f user %.2f sys %.2f maxrss_mb %d minflt %d majflt %d inblock %d oublock %d vcsw %d ivcsw %d"%(w,r.ru_utime,r.ru_stime,r.ru_maxrss/1024,r.ru_minflt,r.ru_majflt,r.ru_inblock,r.ru_oublock,r.ru_nvcsw,r.ru_nivcsw))
