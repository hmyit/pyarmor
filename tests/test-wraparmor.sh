PYTHON=C:/Python27/python
WORKPATH=__test_wrapper__
PYARMOR="$PYTHON $WORKPATH/pyarmor-3.7.0/src/pyarmor.py"
SCRIPT=a.py
SCRIPT_OBF=b.py

mkdir -p $WORKPATH
(cd $WORKPATH; unzip ../../dist/pyarmor-3.7.0.zip > /dev/null)

REPEAT_CODE_HOLDER="i += 1"
let -i n=100
while (( n )) ; do
    REPEAT_CODE_HOLDER=$(echo -e "${REPEAT_CODE_HOLDER}\n        i += 1")
    let n=n-1
done

cat <<EOF > $WORKPATH/${SCRIPT}

def foo():
    if 0:
        i = 0
        ${REPEAT_CODE_HOLDER}

def main():
    for i in range(1000):
        foo()

if __name__ == '__main__':
    import time
    t1 = time.clock()
    main()
    t2 = time.clock()
    print ("Elapse time: %fms" % ((t2 - t1) * 1000))

EOF

cat <<EOF > $WORKPATH/${SCRIPT_OBF}

try:
    from builtins import __wraparmor__
except Exception:
   from __builtin__ import __wraparmor__

def wraparmor(func):
    def wrapper(*args, **kwargs):
         __wraparmor__(func)
         try:
             return func(*args, **kwargs)
         finally:
             __wraparmor__(func, 1)
    wrapper.__module__ = func.__module__
    wrapper.__name__ = func.__name__
    wrapper.__doc__ = func.__doc__
    wrapper.__dict__.update(func.__dict__)
    func.__refcalls__ = 0
    return wrapper

@wraparmor
def foo():
    if 0:
        i = 0
        ${REPEAT_CODE_HOLDER}

@wraparmor
def main():
    for i in range(1000):
        foo()

if __name__ == '__main__':
    import time
    t1 = time.clock()
    main()
    t2 = time.clock()
    print ("Elapse time: %fms" % ((t2 - t1) * 1000))

EOF

#
# Obfuscate script
#
$PYARMOR obfuscate --src $WORKPATH --entry ${SCRIPT_OBF} --output=$WORKPATH/dist ${SCRIPT_OBF}

echo "------------------------------"
echo Run obfuscated script ${SCRIPT_OBF} with decorator
(cd $WORKPATH/dist; $PYTHON ${SCRIPT_OBF})

#
# Get baseline
#
echo "------------------------------"
echo Run normal script ${SCRIPT}
$PYTHON $WORKPATH/${SCRIPT}


# Clean workpath
rm -rf ${WORKPATH}