// Prior-art cost probe: Yjs 13.6.20 and Automerge 2.2.8 over three workloads.
import * as Y from 'yjs'
import * as A from '@automerge/automerge/next'

const N = 1000          // todos
const EDITS = 10000     // field writes
const CHARS = 10000     // typed characters
const t = () => performance.now()
const heap = () => { global.gc?.(); return process.memoryUsage().heapUsed }

function yjs() {
  const out = {}
  const d = new Y.Doc(); d.clientID = 1
  const list = d.getArray('todos')
  let ups = []
  d.on('update', u => ups.push(u.length))
  const h0 = heap()
  for (let i = 0; i < N; i++) { const m = new Y.Map(); m.set('id', i); m.set('title', 'task ' + i); m.set('done', false); list.push([m]) }
  out.insert_bytes_per_todo = ups.reduce((a, b) => a + b, 0) / N; ups = []
  for (let i = 0; i < EDITS; i++) list.get(i % N).set('done', i % 2 === 0)
  out.field_write_bytes = ups.reduce((a, b) => a + b, 0) / EDITS; ups = []
  const txt = d.getText('chat')
  for (let i = 0; i < CHARS; i++) txt.insert(i, 'a')
  out.char_bytes = ups.reduce((a, b) => a + b, 0) / CHARS; ups = []
  out.doc_bytes = Y.encodeStateAsUpdate(d).length
  out.heap_bytes = heap() - h0
  // merge: a peer with the same history applies 10k concurrent edits from another peer
  const base = Y.encodeStateAsUpdate(d)
  const p = new Y.Doc(); p.clientID = 2; Y.applyUpdate(p, base)
  const pl = p.getArray('todos'); const pu = []
  p.on('update', u => pu.push(u))
  for (let i = 0; i < EDITS; i++) pl.get(i % N).set('title', 'p' + i)
  const merged = Y.mergeUpdates(pu)
  let s = t(); Y.applyUpdate(d, merged); out.merge_10k_ms = +(t() - s).toFixed(2)
  out.merge_batch_bytes = merged.length
  // delete half, then measure the doc (tombstones)
  d.transact(() => { for (let i = N - 1; i >= 0; i -= 2) list.delete(i, 1) })
  out.doc_after_delete_half = Y.encodeStateAsUpdate(d).length
  s = t(); const cold = new Y.Doc(); Y.applyUpdate(cold, Y.encodeStateAsUpdate(d)); out.load_ms = +(t() - s).toFixed(2)
  return out
}

function am() {
  const out = {}
  const h0 = heap()
  let d = A.from({ todos: [] }, { actor: '01' })
  let last = A.getHeads(d)
  const inc = () => { const b = A.saveSince(d, last); last = A.getHeads(d); return b.length }
  let sum = 0
  for (let i = 0; i < N; i++) { d = A.change(d, x => { x.todos.push({ id: i, title: 'task ' + i, done: false }) }); sum += inc() }
  out.insert_bytes_per_todo = sum / N; sum = 0
  for (let i = 0; i < EDITS; i++) { d = A.change(d, x => { x.todos[i % N].done = i % 2 === 0 }); sum += inc() }
  out.field_write_bytes = sum / EDITS; sum = 0
  d = A.change(d, x => { x.chat = '' })
  inc()
  for (let i = 0; i < CHARS; i++) { d = A.change(d, x => { A.splice(x, ['chat'], i, 0, 'a') }); sum += inc() }
  out.char_bytes = sum / CHARS
  out.doc_bytes = A.save(d).length
  out.heap_bytes = heap() - h0
  let p = A.clone(d, { actor: '02' })
  const h = A.getHeads(p)
  for (let i = 0; i < EDITS; i++) p = A.change(p, x => { x.todos[i % N].title = 'p' + i })
  const batch = A.saveSince(p, h)
  let s = t(); d = A.loadIncremental(d, batch); out.merge_10k_ms = +(t() - s).toFixed(2)
  out.merge_batch_bytes = batch.length
  d = A.change(d, x => { for (let i = N - 1; i >= 0; i -= 2) x.todos.deleteAt(i) })
  out.doc_after_delete_half = A.save(d).length
  s = t(); A.load(A.save(d)); out.load_ms = +(t() - s).toFixed(2)
  return out
}

console.log('yjs', JSON.stringify(yjs()))
console.log('automerge', JSON.stringify(am()))
