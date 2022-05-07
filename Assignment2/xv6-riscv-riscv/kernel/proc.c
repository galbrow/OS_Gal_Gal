#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"

struct cpu cpus[NCPU];

struct proc proc[NPROC];

//beginning
struct proc lists_heads[5];
//0= running_head; // Dummy link to the index of the first node in the list. if the list is empty it holds -1
//1= unused_head;
//2= runnable_head;
//3= sleeping_head;
//4= zombie_head;

//runnable lists for each cpu
struct proc runnable_heads[NCPU];

//end

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);

static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S
extern uint64 cas(volatile void *addr, int expected, int newval);

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

void printList(struct proc *head){
    printf("------------------------------Printlist----------------------------------- \n");
    while(head->next != -1){
//        printf("Proc address: %x\n", head);
        printf("Proc index in proc arr: %d\n", head - proc);
//        printf("Proc->next %d\n", head.next);
        head = &proc[head->next];
    }
    printf("Proc index in proc arr: %d\n", head - proc);
    printf("-------------------------------------------------------------------\n");

}


//validate
int validate(struct proc *pred, struct proc *curr, int list_index) {
//    printf("validate\n");
    struct proc *node = &lists_heads[list_index];
    if (list_index == 2) //if remove from runnable then go to cpu list
        node = &runnable_heads[get_cpu()];
    while (node->next != -1) { // while I'm not the last node in the list
//        printf("node->next %d\n", node->next);
        if (node == pred) {// Node pred still accessible
//            printf("inside if\n");
            return &proc[pred->next] == curr; }// Node pred.next still successor to curr
        node = &proc[node->next];
    }
    return 0;
}


// Remove
int remove(struct proc *item, int list_index) {
//    printf("remove: proc index: %d from list num: %d\n", item - proc, list_index);
    while (1) {
        struct proc *pred = &lists_heads[list_index];
        if (list_index == 2) //if remove from runnable then go to cpu list
            pred = &runnable_heads[get_cpu()];

        struct proc *curr = &proc[pred->next];

        while (pred->next != -1 && item != &proc[pred->next]) {
            pred = curr;
            curr = &proc[curr->next];
        }

        acquire(&pred->next_lock);
        acquire(&curr->next_lock);
        if (validate(pred, curr, list_index)) {
            if (curr == item) {
                pred->next = curr->next;
                release(&pred->next_lock);
                release(&curr->next_lock);
                return 1;
            } else {
                release(&pred->next_lock);
                release(&curr->next_lock);
                return 0;
            }
        }
    }
}

int add(struct proc *item, int list_index, int cpu_num) {
//    printf("add: proc index: %d to list num: %d\n", item - proc, list_index);
    while (1) {
        struct proc *pred = &lists_heads[list_index];
        if (list_index == 2){//if remove from runnable then go to cpu list
            if(cpu_num == -1)
                pred = &runnable_heads[get_cpu()];
            else
                pred = &runnable_heads[cpu_num];
        }

        acquire(&pred->next_lock);

        if(pred->next == -1) {
            pred->next = item - proc;  //a -> b // item-proc gives the item's index
            item->next = -1; // b->END_OF_LIST
            release(&pred->next_lock);
            return 1;
            //create next proc
        } else{
            struct proc *curr = &proc[pred->next];
            acquire(&curr->next_lock);

            if (validate(pred, curr, list_index)) {
                item->next = pred->next; // b->c
                pred->next = item - proc; //a -> b
                release(&pred->next_lock);
                release(&curr->next_lock);
                return 1;
            }
        }
    }
}

int remove_first_in_line(int list_index){
//    printf("remove first in line\n");
//    printList(&lists_heads[list_index]);
    while (1) {
        struct proc *pred = &lists_heads[list_index];
        if (list_index == 2) //if remove from runnable then go to cpu list
            pred = &runnable_heads[get_cpu()];

        struct proc *curr = &proc[pred->next];
        if(pred->next == -1) //if line is empty
            return -1;

        while (curr->next != -1) { //stop when pred -> curr -> -1 ==== when curr is the last
            pred = curr;
            curr = &proc[curr->next];
        }

        acquire(&pred->next_lock);
        acquire(&curr->next_lock);
        if (validate(pred, curr, list_index)) {
            pred->next = curr->next; //curr->next is -1
            release(&pred->next_lock);
            release(&curr->next_lock);
            return curr - proc;
        }
        release(&pred->next_lock);
        release(&curr->next_lock);
    }
}

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
        char *pa = kalloc();
        if (pa == 0)
            panic("kalloc");
        uint64 va = KSTACK((int) (p - proc));
        kvmmap(kpgtbl, va, (uint64) pa, PGSIZE, PTE_R | PTE_W);
    }
}

// initialize the proc table at boot time.
void
procinit(void) {
    struct proc *p;
    //init all the locks of the lists's head
    for (p = lists_heads; p < &lists_heads[5]; p++) {
        initlock(&p->lock, "proc");
        initlock(&p-> next_lock, "next_lock"); //init next_lock
        acquire(&p->next_lock);
        p->next = -1;
        release(&p->next_lock);
        p->kstack = KSTACK((int) (p - proc));
    }

    //init runnable list for each cpu
    struct cpu *c;
    for (c = cpus; c < &cpus[NCPU]; c++){
        c->runnable_head = &runnable_heads[c-cpus];
        struct proc *head = c->runnable_head;
        initlock(&head->lock, "lock");
        initlock(&head->next_lock, "next_lock");
        acquire(&head->next_lock);
        head->next = -1;
        release(&head->next_lock);
    }

    initlock(&pid_lock, "nextpid");
    initlock(&wait_lock, "wait_lock");
    for (p = proc; p < &proc[NPROC]; p++) {
        initlock(&p->lock, "proc");
        initlock(&p-> next_lock, "next_lock"); //init next_lock
        p->kstack = KSTACK((int) (p - proc));
        add(p, 1, -1); //add all the processes to Unused list at init
    }

//    printf("printlist: 0\n");
//    printList(&lists_heads[1]);
//    printf("remove 60 from the list\n");
//    remove(&proc[60], 1);
//    printList(&lists_heads[1]);
//    printf("add 60\n");
//    add(&proc[60], 1);
//    printList(&lists_heads[1]);
//    printf("remove first in line\n");
//    remove_first_in_line(1);
//    printList(&lists_heads[1]);

}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid() {
    int id = r_tp();
    return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void) {
    int id = cpuid();
    struct cpu *c = &cpus[id];
    return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void) {
    push_off();
    struct cpu *c = mycpu();
    struct proc *p = c->proc;
    pop_off();
    return p;
}

//1 i n t count e r = 0 ;
//2 i n t increment ( ) {
//    3 i n t old ;
//    4 do {
//        5 old = count e r ;
//        6 } whi l e ( cas (&counter , old , old+1) ) ;
//    7 r e turn old ;
//    8 }

int
allocpid() {
    int pid;
    do {
        pid = nextpid;
    } while (cas(&nextpid, pid, pid + 1));
    return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void) {
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if (p->state == UNUSED) {
            goto found;
        } else {
            release(&p->lock);
        }
    }
    return 0;

    found:
    p->pid = allocpid();
    p->state = USED;

    // Allocate a trapframe page.
    if ((p->trapframe = (struct trapframe *) kalloc()) == 0) {
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    // An empty user page table.
    p->pagetable = proc_pagetable(p);
    if (p->pagetable == 0) {
        freeproc(p);
        release(&p->lock);
        return 0;
    }

    // Set up new context to start executing at forkret,
    // which returns to user space.
    memset(&p->context, 0, sizeof(p->context));
    p->context.ra = (uint64) forkret;
    p->context.sp = p->kstack + PGSIZE;

    return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p) {
    //remove from zombie list and add to unused
    if(remove(p, 4) == 1)
        add(p, 1, -1);

    if (p->trapframe)
        kfree((void *) p->trapframe);
    p->trapframe = 0;
    if (p->pagetable)
        proc_freepagetable(p->pagetable, p->sz);
    p->pagetable = 0;
    p->sz = 0;
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->chan = 0;
    p->killed = 0;
    p->xstate = 0;
    p->state = UNUSED;
    p->cpu = 0;

}

// Create a user page table for a given process,
// with no user memory, but with trampoline pages.
pagetable_t
proc_pagetable(struct proc *p) {
    pagetable_t pagetable;

    // An empty page table.
    pagetable = uvmcreate();
    if (pagetable == 0)
        return 0;

    // map the trampoline code (for system call return)
    // at the highest user virtual address.
    // only the supervisor uses it, on the way
    // to/from user space, so not PTE_U.
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
                 (uint64) trampoline, PTE_R | PTE_X) < 0) {
        uvmfree(pagetable, 0);
        return 0;
    }

    // map the trapframe just below TRAMPOLINE, for trampoline.S.
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
                 (uint64) (p->trapframe), PTE_R | PTE_W) < 0) {
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
        uvmfree(pagetable, 0);
        return 0;
    }

    return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz) {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// od -t xC initcode
uchar initcode[] = {
        0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
        0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
        0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
        0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
        0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
        0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void) {
    struct proc *p;

    p = allocproc();
    initproc = p;

    // allocate one user page and copy init's instructions
    // and data into it.
    uvminit(p->pagetable, initcode, sizeof(initcode));
    p->sz = PGSIZE;

    // prepare for the very first "return" from kernel to user.
    p->trapframe->epc = 0;      // user program counter
    p->trapframe->sp = PGSIZE;  // user stack pointer

    safestrcpy(p->name, "initcode", sizeof(p->name));
    p->cwd = namei("/");

    // remove from unused list and add to runnable
    if(remove(p, 1) == 1)
        add(p, 2, 0); //TODO: check -> add the proc to the first cpu list (0)

    p->state = RUNNABLE;

    release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n) {
    uint sz;
    struct proc *p = myproc();

    sz = p->sz;
    if (n > 0) {
        if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
            return -1;
        }
    } else if (n < 0) {
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    }
    p->sz = sz;
    return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void) {
    int i, pid;
    struct proc *np;
    struct proc *p = myproc();

    // Allocate process.
    if ((np = allocproc()) == 0) {
        return -1;
    }

    // Copy user memory from parent to child.
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0) {
        freeproc(np);
        release(&np->lock);
        return -1;
    }
    np->sz = p->sz;

    // copy saved user registers.
    *(np->trapframe) = *(p->trapframe);

    // Cause fork to return 0 in the child.
    np->trapframe->a0 = 0;

    // increment reference counts on open file descriptors.
    for (i = 0; i < NOFILE; i++)
        if (p->ofile[i])
            np->ofile[i] = filedup(p->ofile[i]);
    np->cwd = idup(p->cwd);

    safestrcpy(np->name, p->name, sizeof(p->name));

    pid = np->pid;

    release(&np->lock);

    acquire(&wait_lock);
    np->parent = p;
    release(&wait_lock);

    acquire(&np->lock);
    // remove from unused list and add to runnable
    if(remove(np, 1) ==1)
        add(np, 2, get_cpu()); //TODO: check that get_cpu return the father's cpu id



    np->state = RUNNABLE;
    release(&np->lock);

    return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p) {
    struct proc *pp;

    for (pp = proc; pp < &proc[NPROC]; pp++) {
        if (pp->parent == p) {
            pp->parent = initproc;
            wakeup(initproc);
        }
    }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status) {
    struct proc *p = myproc();

    if (p == initproc)
        panic("init exiting");

    // Close all open files.
    for (int fd = 0; fd < NOFILE; fd++) {
        if (p->ofile[fd]) {
            struct file *f = p->ofile[fd];
            fileclose(f);
            p->ofile[fd] = 0;
        }
    }

    begin_op();
    iput(p->cwd);
    end_op();
    p->cwd = 0;

    acquire(&wait_lock);

    // Give any children to init.
    reparent(p);

    // Parent might be sleeping in wait().
    wakeup(p->parent);

    acquire(&p->lock);

    p->xstate = status;
    //todo
    //remove from running list and add to zombie list
    if(remove(p, 0) == 1)
        add(p, 4, -1);
    p->state = ZOMBIE;

    release(&wait_lock);

    // Jump into the scheduler, never to return.
    sched();
    panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr) {
    struct proc *np;
    int havekids, pid;
    struct proc *p = myproc();

    acquire(&wait_lock);

    for (;;) {
        // Scan through table looking for exited children.
        havekids = 0;
        for (np = proc; np < &proc[NPROC]; np++) {
            if (np->parent == p) {
                // make sure the child isn't still in exit() or swtch().
                acquire(&np->lock);

                havekids = 1;
                if (np->state == ZOMBIE) {
                    // Found one.
                    pid = np->pid;
                    if (addr != 0 && copyout(p->pagetable, addr, (char *) &np->xstate,
                                             sizeof(np->xstate)) < 0) {
                        release(&np->lock);
                        release(&wait_lock);
                        return -1;
                    }
                    freeproc(np);
                    release(&np->lock);
                    release(&wait_lock);
                    return pid;
                }
                release(&np->lock);
            }
        }

        // No point waiting if we don't have any children.
        if (!havekids || p->killed) {
            release(&wait_lock);
            return -1;
        }

        // Wait for a child to exit.
        sleep(p, &wait_lock);  //DOC: wait-sleep
    }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void
scheduler(void) {
    struct proc *p;
    struct cpu *c = mycpu();
//    int cpu_num = c- cpus;

    c->proc = 0;
    for (;;) {
        // Avoid deadlock by ensuring that devices can interrupt.
        intr_on();
        int p_index = remove_first_in_line(2);
        if(p_index == -1)
            continue;
        p = &proc[p_index];
        acquire(&p->lock);
        if (p->state == RUNNABLE) {
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            //todo
            //add to Running list
            add(p, 0, -1); //todo remove
            p->cpu = get_cpu();
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;

            release(&p->lock);
        }
    }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void) {
    int intena;
    struct proc *p = myproc();

    if (!holding(&p->lock))
        panic("sched p->lock");
    if (mycpu()->noff != 1)
        panic("sched locks");
    if (p->state == RUNNING)
        panic("sched running");
    if (intr_get())
        panic("sched interruptible");

    intena = mycpu()->intena;
    swtch(&p->context, &mycpu()->context);
    mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void) {
    struct proc *p = myproc();
    acquire(&p->lock);
    //todo
    //remove from Running list and add to runnable
    if(remove(p, 0) == 1)
        add(p, 2, get_cpu()); //TODO: check
    p->state = RUNNABLE;
    sched();
    release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void) {
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);

    if (first) {
        // File system initialization must be run in the context of a
        // regular process (e.g., because it calls sleep), and thus cannot
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk) {
    struct proc *p = myproc();
    // Must acquire p->lock in order to
    // change p->state and then call sched.
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock);  //DOC: sleeplock1
    release(lk);
    //todo
    //remove from running list and add to sleeping list
    if(remove(p, 0) == 1)
        add(p, 3, -1);

    // Go to sleep.
    p->chan = chan;
    p->state = SLEEPING;

    sched();


    // Tidy up.
    p->chan = 0;

    // Reacquire original lock.
    release(&p->lock);
    acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan) {
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
        if (p != myproc()) {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan) {
                //todo
                //remove from sleeping and add to runnable
                if(remove(p, 3) == 1)
                    add(p, 2, p->cpu);
                p->state = RUNNABLE;
            }
            release(&p->lock);
        }
    }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid) {
    printf("kill\n");
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++) {
        acquire(&p->lock);
        if (p->pid == pid) {
            p->killed = 1;
            if (p->state == SLEEPING) {
                // Wake process from sleep().
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    }
    printf("end kill\n");
    return -1;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len) {
    struct proc *p = myproc();
    if (user_dst) {
        return copyout(p->pagetable, dst, src, len);
    } else {
        memmove((char *) dst, src, len);
        return 0;
    }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len) {
    struct proc *p = myproc();
    if (user_src) {
        return copyin(p->pagetable, dst, src, len);
    } else {
        memmove(dst, (char *) src, len);
        return 0;
    }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void) {
    static char *states[] = {
            [UNUSED]    "unused",
            [SLEEPING]  "sleep ",
            [RUNNABLE]  "runble",
            [RUNNING]   "run   ",
            [ZOMBIE]    "zombie"
    };
    struct proc *p;
    char *state;

    printf("\n");
    for (p = proc; p < &proc[NPROC]; p++) {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
            state = states[p->state];
        else
            state = "???";
        printf("%d %s %s", p->pid, state, p->name);
        printf("\n");
    }
}

int set_cpu(int cpu_num) {
    struct proc *p = myproc();
    if(remove(p, 0) == 0) //for our debug
        return -1;

    add(p, 2, cpu_num);
    p-> cpu = cpu_num;
    yield();
    return cpu_num; //todo impl
}

int get_cpu() {
//    printf("mycpu: %d\n", mycpu());
//    printf("cpu index: %d\n", mycpu()-cpus);
    return mycpu() - cpus; //todo check!!!!
}

